from django.db import transaction

from apps.common.broadcast import broadcast
from apps.common.errors import Conflict, Forbidden, NotFound

from .models import Argument, Debate, DebateStatus, Participant, Role, Side

ROLE_TO_SIDE = {Role.TEAM_A: Side.TEAM_A, Role.TEAM_B: Side.TEAM_B}


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
    return argument


def _ask_the_referee(argument: Argument) -> None:
    """Queue the analysis, and show a pending card while the worker gets to it."""
    # TODO(step 4): nothing happens yet, so the debate still works exactly as it
    # did in phase 2. Create the Analysis row here so the UI has something to
    # show, then enqueue apps.referee.jobs.analyze_argument on the "referee"
    # queue. The enqueue belongs in transaction.on_commit: a worker in another
    # process must not look for a row this transaction has not committed yet.
    return


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
