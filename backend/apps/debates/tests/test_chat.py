from datetime import timedelta

import pytest
from rest_framework.exceptions import ValidationError
from rest_framework.test import APIClient

from apps.common.errors import Conflict, NotFound
from apps.debates import services
from apps.debates.models import ChatMessage, DebateStatus, Role
from apps.debates.selectors import chat_messages_recent
from apps.debates.services import (
    chat_message_delete,
    chat_message_send,
    debate_create,
    debate_join,
)

pytestmark = pytest.mark.django_db


@pytest.fixture
def room():
    """A debate still in the lobby, with one of every kind of person in it."""
    debate, moderator = debate_create(topic="Cats beat dogs", display_name="Mo")
    _, team_a = debate_join(join_code=debate.join_code, display_name="A", role=Role.TEAM_A)
    _, viewer = debate_join(
        join_code=debate.join_code, display_name="Viewer", role=Role.AUDIENCE
    )
    return debate, moderator, team_a, viewer


@pytest.fixture
def no_rate_limit(monkeypatch):
    """Most of these tests are about what was said, not how fast."""
    monkeypatch.setattr(services, "CHAT_MIN_INTERVAL", timedelta(0))


def test_everyone_can_chat_before_the_debate_starts(room, no_rate_limit):
    debate, moderator, team_a, viewer = room
    assert debate.status == DebateStatus.LOBBY

    for participant in (moderator, team_a, viewer):
        chat_message_send(debate=debate, participant=participant, body="hello")

    assert ChatMessage.objects.filter(debate=debate).count() == 3


def test_a_message_carries_the_name_and_role_of_its_sender(room):
    debate, _, _, viewer = room

    message = chat_message_send(debate=debate, participant=viewer, body="go team A")

    assert message.author_name == "Viewer"
    assert message.author_role == Role.AUDIENCE
    assert message.body == "go team A"
    assert not message.is_deleted


def test_the_sender_leaving_does_not_anonymise_the_transcript(room):
    debate, _, _, viewer = room
    chat_message_send(debate=debate, participant=viewer, body="bye")

    viewer.delete()

    message = ChatMessage.objects.get(debate=debate)
    assert message.participant_id is None
    assert message.author_name == "Viewer"


def test_chatting_too_fast_is_a_conflict(room):
    debate, _, _, viewer = room
    chat_message_send(debate=debate, participant=viewer, body="one")

    with pytest.raises(Conflict):
        chat_message_send(debate=debate, participant=viewer, body="two")


def test_the_limit_is_per_person_not_per_room(room):
    debate, _, team_a, viewer = room
    chat_message_send(debate=debate, participant=viewer, body="one")

    # Nobody else is slowed down by somebody else's enthusiasm.
    chat_message_send(debate=debate, participant=team_a, body="two")

    assert ChatMessage.objects.filter(debate=debate).count() == 2


@pytest.mark.parametrize("body", ["", "   ", "\n"])
def test_an_empty_message_is_rejected(room, body):
    debate, _, _, viewer = room

    with pytest.raises(ValidationError):
        chat_message_send(debate=debate, participant=viewer, body=body)


def test_history_is_oldest_first_and_capped_to_the_tail(room, no_rate_limit):
    debate, _, _, viewer = room
    for word in ["one", "two", "three"]:
        chat_message_send(debate=debate, participant=viewer, body=word)

    assert [m.body for m in chat_messages_recent(debate.id)] == ["one", "two", "three"]
    # A cap keeps the newest, not the first ones ever typed.
    assert [m.body for m in chat_messages_recent(debate.id, limit=2)] == ["two", "three"]


def test_a_removed_message_keeps_its_place_but_loses_its_words(room, no_rate_limit):
    from apps.debates.serializers import ChatMessageOutSerializer

    debate, _, _, viewer = room
    chat_message_send(debate=debate, participant=viewer, body="first")
    rude = chat_message_send(debate=debate, participant=viewer, body="something rude")
    chat_message_send(debate=debate, participant=viewer, body="third")

    chat_message_delete(debate=debate, message_id=rude.id)

    rows = ChatMessageOutSerializer(chat_messages_recent(debate.id), many=True).data
    assert [r["body"] for r in rows] == ["first", "", "third"]
    assert [r["is_deleted"] for r in rows] == [False, True, False]


def test_removing_a_removed_message_is_a_no_op(room):
    debate, _, _, viewer = room
    message = chat_message_send(debate=debate, participant=viewer, body="oops")

    chat_message_delete(debate=debate, message_id=message.id)
    first = ChatMessage.objects.get(pk=message.id).deleted_at

    chat_message_delete(debate=debate, message_id=message.id)

    assert ChatMessage.objects.get(pk=message.id).deleted_at == first


def test_removing_an_unknown_message_is_not_found(room):
    debate, _, _, _ = room

    with pytest.raises(NotFound):
        chat_message_delete(
            debate=debate, message_id="00000000-0000-0000-0000-000000000000"
        )


# --- over HTTP -----------------------------------------------------------


def auth(token):
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Participant {token}")
    return client


def test_the_backlog_needs_a_token(room):
    debate, moderator, _, _ = room

    assert APIClient().get(f"/api/debates/{debate.id}/chat/").status_code == 401

    response = auth(moderator.token).get(f"/api/debates/{debate.id}/chat/")
    assert response.status_code == 200
    assert response.data == []


def test_the_backlog_reads_back_what_was_sent(room, no_rate_limit):
    debate, moderator, _, viewer = room
    chat_message_send(debate=debate, participant=viewer, body="hello")
    chat_message_send(debate=debate, participant=moderator, body="welcome")

    rows = auth(moderator.token).get(f"/api/debates/{debate.id}/chat/").data

    assert [r["body"] for r in rows] == ["hello", "welcome"]
    assert [r["author_name"] for r in rows] == ["Viewer", "Mo"]
    assert [r["author_role"] for r in rows] == [Role.AUDIENCE, Role.MODERATOR]


def test_only_the_moderator_can_remove_a_message(room):
    debate, moderator, team_a, viewer = room
    message = chat_message_send(debate=debate, participant=viewer, body="something rude")
    path = f"/api/debates/{debate.id}/chat/{message.id}/"

    assert auth(team_a.token).delete(path).status_code == 403
    assert auth(viewer.token).delete(path).status_code == 403
    assert auth(moderator.token).delete(path).status_code == 204

    assert ChatMessage.objects.get(pk=message.id).is_deleted
