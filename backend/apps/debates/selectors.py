from apps.common.errors import NotFound

from .models import Debate


def debate_get(debate_id) -> Debate:
    debate = (
        Debate.objects.prefetch_related("participants", "arguments__participant")
        .filter(pk=debate_id)
        .first()
    )
    if debate is None:
        raise NotFound("No such debate.")
    return debate
