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
    if debate.status != DebateStatus.VOTING:
        raise Conflict("Voting is not open for this debate.")
    if Vote.objects.filter(debate=debate, participant=participant).exists():
        raise Conflict("You have already voted.")

    vote = Vote.objects.create(debate=debate, participant=participant, choice=choice)

    # The count just changed, so the cached one is wrong.
    cache.delete(tally_key(debate.id))
    _announce(debate)
    return vote


@transaction.atomic
def debate_close(*, debate: Debate) -> Debate:
    if debate.status != DebateStatus.VOTING:
        raise Conflict("Only a debate in voting can be closed.")
    debate.status = DebateStatus.CLOSED
    debate.save(update_fields=["status"])
    _announce(debate)
    return debate
