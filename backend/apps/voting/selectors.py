from django.core.cache import cache
from django.db.models import Count

from apps.debates.models import Side

from .models import Vote


def tally_key(debate_id) -> str:
    return f"debate:{debate_id}:tally"


def vote_tally(debate) -> dict:
    """Counts per side, cached for a moment so a full room refreshing costs one query."""
    # TODO(step 1): return the cached tally when there is one. Otherwise count
    # votes per side with values_list + annotate, shape them as
    # {"team_a", "team_b", "total"}, cache that for 2 seconds, and return it.
    raise NotImplementedError
