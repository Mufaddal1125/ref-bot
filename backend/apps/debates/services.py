from datetime import timedelta

from django.db import transaction
from django.utils import timezone

from apps.common.broadcast import broadcast
from apps.common.errors import Conflict, Forbidden, NotFound

from .models import Argument, ChatMessage, Debate, DebateStatus, Participant, Role, Side

ROLE_TO_SIDE = {Role.TEAM_A: Side.TEAM_A, Role.TEAM_B: Side.TEAM_B}

# One line every two seconds is a conversation; faster than that is a flood, and
# a flood on a projector in front of two hundred people is somebody's afternoon.
CHAT_MIN_INTERVAL = timedelta(seconds=2)


def _announce(debate: Debate) -> None:
    """Tell every watcher the debate changed, once the change is really saved."""
    from .selectors import debate_get
    from .serializers import DebateDetailSerializer

    transaction.on_commit(
        lambda: broadcast(
            debate.id, "debate.updated", DebateDetailSerializer(debate_get(debate.id)).data
        )
    )


@transaction.atomic
def debate_create(*, topic: str, display_name: str) -> tuple[Debate, Participant]:
    """Open a debate and make its creator the moderator."""
    debate = Debate.objects.create(topic=topic)
    moderator = Participant.objects.create(
        debate=debate, display_name=display_name, role=Role.MODERATOR
    )
    return debate, moderator


@transaction.atomic
def debate_join(*, join_code: str, display_name: str, role: str) -> tuple[Debate, Participant]:
    debate = Debate.objects.filter(join_code=join_code.strip().upper()).first()
    if debate is None:
        raise NotFound("No debate has that join code.")
    if role == Role.MODERATOR:
        raise Forbidden("A debate has one moderator, set when it is created.")
    # max 5 participants on either side
    if role in (Role.TEAM_A, Role.TEAM_B):
        role_count = Participant.objects.filter(debate=debate, role=role).count()
        if role_count >= 5:
            raise Forbidden(f"Side: {ROLE_TO_SIDE[role].label} already has {role_count} participant.")

    participant = Participant.objects.create(
        debate=debate, display_name=display_name, role=role
    )
    return debate, participant


@transaction.atomic
def argument_submit(*, debate: Debate, participant: Participant, body: str) -> Argument:
    """Record an argument and hand the turn to the other side."""
    # Two teammates can hit submit at once; lock the turn counter.
    debate = Debate.objects.select_for_update().get(pk=debate.pk)

    if debate.status != DebateStatus.ACTIVE:
        raise Conflict("This debate is not taking arguments right now.")

    side = ROLE_TO_SIDE.get(participant.role)
    if side is None:
        raise Forbidden("Only Team A and Team B can argue.")
    if side != debate.current_side:
        raise Conflict("It is the other team's turn.")

    argument = Argument.objects.create(
        debate=debate,
        participant=participant,
        side=side,
        round_number=debate.current_round,
        body=body,
    )

    if side == Side.TEAM_A:
        debate.current_side = Side.TEAM_B
    else:
        debate.current_side = Side.TEAM_A
        debate.current_round += 1
    debate.save(update_fields=["current_side", "current_round"])

    _ask_the_referee(argument)
    _announce(debate)

    # auto end after 12 rounds
    if debate.current_round > 12:
        debate_end(debate=debate)

    return argument


def _ask_the_referee(argument: Argument) -> None:
    """Queue the analysis, and show a pending card while the worker gets to it."""
    import django_rq

    from apps.referee.models import Analysis

    Analysis.objects.create(argument=argument)
    transaction.on_commit(
        lambda: django_rq.get_queue("referee").enqueue(
            "apps.referee.jobs.analyze_argument", argument.id
        )
    )


@transaction.atomic
def debate_start(*, debate: Debate) -> Debate:
    if debate.status != DebateStatus.LOBBY:
        raise Conflict("This debate has already started.")
    debate.status = DebateStatus.ACTIVE
    debate.save(update_fields=["status"])
    _announce(debate)
    return debate


@transaction.atomic
def debate_end(*, debate: Debate) -> Debate:
    if debate.status != DebateStatus.ACTIVE:
        raise Conflict("Only a running debate can be ended.")
    debate.status = DebateStatus.VOTING
    debate.save(update_fields=["status"])
    _announce(debate)
    return debate


# --- chat ----------------------------------------------------------------
#
# Chat does not go through _announce. A debate.updated carries every argument,
# every analysis and the tally; sending all of that again because somebody typed
# "lol" would cost more than the debate itself. Each chat event carries one row.


def _announce_chat(debate_id, type_: str, payload: dict) -> None:
    transaction.on_commit(lambda: broadcast(debate_id, type_, payload))


@transaction.atomic
def chat_message_send(*, debate: Debate, participant: Participant, body: str) -> ChatMessage:
    """Anyone in the room, in any phase. The one limit is how fast."""
    from .serializers import ChatMessageCreateSerializer, ChatMessageOutSerializer

    # Validated here rather than at the edge: the socket has no DRF view to do
    # it, and one door means one set of rules.
    payload = ChatMessageCreateSerializer(data={"body": body})
    payload.is_valid(raise_exception=True)

    latest = (
        ChatMessage.objects.filter(debate=debate, participant=participant)
        .order_by("-created_at")
        .first()
    )
    if latest is not None and timezone.now() - latest.created_at < CHAT_MIN_INTERVAL:
        raise Conflict("Slow down a moment.")

    message = ChatMessage.objects.create(
        debate=debate,
        participant=participant,
        author_name=participant.display_name,
        author_role=participant.role,
        body=payload.validated_data["body"],
    )

    _announce_chat(debate.id, "chat.message", ChatMessageOutSerializer(message).data)
    return message


@transaction.atomic
def chat_message_delete(*, debate: Debate, message_id) -> ChatMessage:
    """The moderator's remove. Idempotent: removing a removed line is a no-op."""
    message = ChatMessage.objects.filter(pk=message_id, debate=debate).first()
    if message is None:
        raise NotFound("No such message.")

    if not message.is_deleted:
        message.deleted_at = timezone.now()
        message.save(update_fields=["deleted_at"])

    _announce_chat(debate.id, "chat.deleted", {"id": str(message.id)})
    return message
