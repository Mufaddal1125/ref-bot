from apps.common.errors import NotFound

from .models import ChatMessage, Debate

# A room that has been talking all afternoon should not hand a phone that just
# joined every line of it.
CHAT_HISTORY_LIMIT = 200


def debate_get(debate_id) -> Debate:
    debate = (
        Debate.objects.prefetch_related(
            "participants", "votes", "arguments__participant", "arguments__analysis"
        )
        .filter(pk=debate_id)
        .first()
    )
    if debate is None:
        raise NotFound("No such debate.")
    return debate


def chat_messages_recent(debate_id, limit: int = CHAT_HISTORY_LIMIT) -> list[ChatMessage]:
    """The tail of the chat, oldest first — the order a reader wants it in."""
    newest_first = ChatMessage.objects.filter(debate_id=debate_id).order_by("-created_at")
    return list(reversed(newest_first[:limit]))
