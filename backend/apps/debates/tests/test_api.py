import pytest
from rest_framework.test import APIClient

from apps.debates.models import Role

pytestmark = pytest.mark.django_db


def auth(token):
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Participant {token}")
    return client


@pytest.fixture
def debate():
    """A started debate, plus a client per role."""
    client = APIClient()
    created = client.post(
        "/api/debates/", {"topic": "Cats beat dogs", "display_name": "Mo"}, format="json"
    ).data
    code = created["debate"]["join_code"]

    def join(name, role):
        return client.post(
            "/api/debates/join/",
            {"join_code": code, "display_name": name, "role": role},
            format="json",
        ).data

    team_a = join("A", Role.TEAM_A)
    team_b = join("B", Role.TEAM_B)
    debate_id = created["debate"]["id"]
    auth(created["token"]).post(f"/api/debates/{debate_id}/start/")
    return debate_id, created, team_a, team_b


def test_create_returns_a_session():
    response = APIClient().post(
        "/api/debates/", {"topic": "Cats beat dogs", "display_name": "Mo"}, format="json"
    )

    assert response.status_code == 201
    assert response.data["participant"]["role"] == Role.MODERATOR
    assert response.data["token"]


def test_detail_needs_a_token(debate):
    """No token is 401; a token for the wrong debate is 403."""
    debate_id, *_ = debate

    assert APIClient().get(f"/api/debates/{debate_id}/").status_code == 401


def test_a_round_trip_shows_up_in_history(debate):
    debate_id, moderator, team_a, team_b = debate

    assert (
        auth(team_a["token"])
        .post(f"/api/debates/{debate_id}/arguments/", {"body": "Cats are quiet"}, format="json")
        .status_code
        == 201
    )
    assert (
        auth(team_b["token"])
        .post(f"/api/debates/{debate_id}/arguments/", {"body": "Dogs are loyal"}, format="json")
        .status_code
        == 201
    )

    state = auth(moderator["token"]).get(f"/api/debates/{debate_id}/").data
    assert [a["body"] for a in state["arguments"]] == ["Cats are quiet", "Dogs are loyal"]
    assert state["current_round"] == 2


def test_arguing_out_of_turn_is_a_conflict(debate):
    debate_id, _, _, team_b = debate

    response = auth(team_b["token"]).post(
        f"/api/debates/{debate_id}/arguments/", {"body": "me first"}, format="json"
    )

    assert response.status_code == 409
    assert response.data["code"] == "conflict"


def test_only_the_moderator_ends_the_debate(debate):
    debate_id, moderator, team_a, _ = debate

    assert auth(team_a["token"]).post(f"/api/debates/{debate_id}/end/").status_code == 403
    assert auth(moderator["token"]).post(f"/api/debates/{debate_id}/end/").status_code == 200


def test_a_token_from_one_debate_cannot_read_another(debate):
    debate_id, _, team_a, _ = debate
    other = APIClient().post(
        "/api/debates/", {"topic": "Other", "display_name": "Mo2"}, format="json"
    ).data

    response = auth(team_a["token"]).get(f"/api/debates/{other['debate']['id']}/")

    assert response.status_code == 403
