import pytest
from django.core.cache import cache

from apps.common.errors import Conflict
from apps.debates.models import DebateStatus, Role, Side
from apps.debates.services import debate_create, debate_end, debate_join, debate_start
from apps.voting.selectors import vote_tally
from apps.voting.services import debate_close, vote_cast

pytestmark = pytest.mark.django_db


@pytest.fixture
def open_vote():
    """A debate that has ended, with two people who can vote."""
    cache.clear()
    debate, moderator = debate_create(topic="Cats beat dogs", display_name="Mo")
    _, one = debate_join(join_code=debate.join_code, display_name="One", role=Role.AUDIENCE)
    _, two = debate_join(join_code=debate.join_code, display_name="Two", role=Role.AUDIENCE)
    debate_start(debate=debate)
    debate_end(debate=debate)
    debate.refresh_from_db()
    return debate, moderator, one, two


def test_votes_are_counted_per_side(open_vote):
    debate, _, one, two = open_vote

    vote_cast(debate=debate, participant=one, choice=Side.TEAM_A)
    vote_cast(debate=debate, participant=two, choice=Side.TEAM_A)

    assert vote_tally(debate) == {"team_a": 2, "team_b": 0, "total": 2}


def test_a_participant_votes_once(open_vote):
    debate, _, one, _ = open_vote
    vote_cast(debate=debate, participant=one, choice=Side.TEAM_A)

    with pytest.raises(Conflict):
        vote_cast(debate=debate, participant=one, choice=Side.TEAM_B)


def test_voting_before_the_debate_ends_is_refused():
    debate, _ = debate_create(topic="T", display_name="Mo")
    _, one = debate_join(join_code=debate.join_code, display_name="One", role=Role.AUDIENCE)

    with pytest.raises(Conflict):
        vote_cast(debate=debate, participant=one, choice=Side.TEAM_A)


def test_a_new_vote_invalidates_the_cached_tally(open_vote):
    debate, _, one, two = open_vote
    vote_cast(debate=debate, participant=one, choice=Side.TEAM_A)
    assert vote_tally(debate)["total"] == 1

    vote_cast(debate=debate, participant=two, choice=Side.TEAM_B)

    assert vote_tally(debate) == {"team_a": 1, "team_b": 1, "total": 2}


def test_closing_ends_voting(open_vote):
    debate, _, _, _ = open_vote

    debate_close(debate=debate)

    assert debate.status == DebateStatus.CLOSED
    with pytest.raises(Conflict):
        debate_close(debate=debate)
