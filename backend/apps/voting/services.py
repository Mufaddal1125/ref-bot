from django.core.cache import cache
from django.db import transaction

from apps.common.errors import Conflict
from apps.debates.models import Debate, DebateStatus, Participant
from apps.debates.services import _announce

from .models import Vote
from .selectors import tally_key


@transaction.atomic
def vote_cast(*, debate: Debate, participant: Participant, choice: str) -> Vote:
    """One vote per participant, only while voting is open."""
    # TODO(step 2): refuse unless the debate is VOTING, refuse a second vote
    # from the same participant, then create it. The count has changed, so drop
    # the cached tally before announcing - otherwise the whole room sees stale
    # numbers for up to two seconds.
    raise NotImplementedError


@transaction.atomic
def debate_close(*, debate: Debate) -> Debate:
    # TODO(step 2): VOTING -> CLOSED, and refuse anything else.
    raise NotImplementedError
