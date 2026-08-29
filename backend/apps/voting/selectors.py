from django.core.cache import cache
from django.db.models import Count

from apps.debates.models import Side

from .models import Vote


def tally_key(debate_id) -> str:
    return f"debate:{debate_id}:tally"


def vote_tally(debate) -> dict:
    """Counts per side, cached for a moment so a full room refreshing costs one query."""
    cached = cache.get(tally_key(debate.id))
    if cached is not None:
        return cached

    counts = dict(
        Vote.objects.filter(debate=debate)
        .values_list("choice")
        .annotate(total=Count("id"))
    )
    tally = {
        "team_a": counts.get(Side.TEAM_A, 0),
        "team_b": counts.get(Side.TEAM_B, 0),
    }
    tally["total"] = tally["team_a"] + tally["team_b"]

    cache.set(tally_key(debate.id), tally, timeout=2)
    return tally
