import pytest

from apps.common.errors import Conflict, Forbidden, NotFound
from apps.debates.models import DebateStatus, Role, Side
from apps.debates.services import (
    argument_submit,
    debate_create,
    debate_end,
    debate_join,
    debate_start,
)

pytestmark = pytest.mark.django_db


@pytest.fixture
def running_debate():
    """An active debate with both teams present."""
    debate, moderator = debate_create(topic="Cats beat dogs", display_name="Mo")
    _, team_a = debate_join(join_code=debate.join_code, display_name="A", role=Role.TEAM_A)
    _, team_b = debate_join(join_code=debate.join_code, display_name="B", role=Role.TEAM_B)
    debate_start(debate=debate)
    debate.refresh_from_db()
    return debate, moderator, team_a, team_b


def test_create_makes_a_moderator_and_a_join_code():
    debate, moderator = debate_create(topic="Cats beat dogs", display_name="Mo")

    assert len(debate.join_code) == 6
    assert moderator.role == Role.MODERATOR
    assert debate.status == DebateStatus.LOBBY
    assert debate.current_side == Side.TEAM_A


def test_join_is_case_insensitive():
    debate, _ = debate_create(topic="T", display_name="Mo")

    _, participant = debate_join(
        join_code=debate.join_code.lower(), display_name="A", role=Role.TEAM_A
    )

    assert participant.debate_id == debate.id


def test_join_rejects_an_unknown_code():
    with pytest.raises(NotFound):
        debate_join(join_code="ZZZZZZ", display_name="A", role=Role.TEAM_A)


def test_join_refuses_a_second_moderator():
    debate, _ = debate_create(topic="T", display_name="Mo")

    with pytest.raises(Forbidden):
        debate_join(join_code=debate.join_code, display_name="X", role=Role.MODERATOR)


def test_turn_alternates_and_the_round_advances(running_debate):
    debate, _, team_a, team_b = running_debate

    argument_submit(debate=debate, participant=team_a, body="first")
    debate.refresh_from_db()
    assert debate.current_side == Side.TEAM_B
    assert debate.current_round == 1

    argument_submit(debate=debate, participant=team_b, body="second")
    debate.refresh_from_db()
    assert debate.current_side == Side.TEAM_A
    assert debate.current_round == 2


def test_the_wrong_team_cannot_argue(running_debate):
    debate, _, _, team_b = running_debate

    with pytest.raises(Conflict):
        argument_submit(debate=debate, participant=team_b, body="out of turn")


def test_the_moderator_cannot_argue(running_debate):
    debate, moderator, _, _ = running_debate

    with pytest.raises(Forbidden):
        argument_submit(debate=debate, participant=moderator, body="me too")


def test_a_debate_in_the_lobby_takes_no_arguments():
    debate, _ = debate_create(topic="T", display_name="Mo")
    _, team_a = debate_join(join_code=debate.join_code, display_name="A", role=Role.TEAM_A)

    with pytest.raises(Conflict):
        argument_submit(debate=debate, participant=team_a, body="too early")


def test_a_debate_starts_once(running_debate):
    debate, _, _, _ = running_debate

    with pytest.raises(Conflict):
        debate_start(debate=debate)


def test_ending_opens_voting(running_debate):
    debate, _, _, _ = running_debate

    debate_end(debate=debate)

    assert debate.status == DebateStatus.VOTING
