from urllib.parse import parse_qs

from channels.db import database_sync_to_async
from channels.generic.websocket import AsyncJsonWebsocketConsumer
from rest_framework.exceptions import ValidationError

from apps.common.broadcast import group_name
from apps.common.errors import DomainError

from .models import Participant

CLOSE_UNAUTHORIZED = 4401

#: The one thing a client may send up. Everything else still belongs to the API.
CHAT_SEND = "chat.send"


class DebateConsumer(AsyncJsonWebsocketConsumer):
    """Pushes debate state out. The only thing it takes in is chat.

    Debate changes still go through the REST API, because they have turns,
    permissions and a referee hanging off them. A chat line has none of that
    and wants to be instant, so it rides the socket it is already sitting on.
    """

    async def connect(self):
        self.debate_id = self.scope["url_route"]["kwargs"]["debate_id"]

        # Browsers cannot set headers on a WebSocket, so the token rides the query string.
        query = parse_qs(self.scope["query_string"].decode())
        self.participant = await self._participant(query.get("token", [""])[0])

        if self.participant is None:
            # Accept first, so the client gets a real close code instead of a
            # refused upgrade it cannot tell apart from the server being down.
            await self.accept()
            await self.close(code=CLOSE_UNAUTHORIZED)
            return

        self.group = group_name(self.debate_id)
        await self.channel_layer.group_add(self.group, self.channel_name)
        await self.accept()

        # The client answers this by fetching the current state over HTTP, so a
        # reconnect resyncs — the debate and the chat backlog both — without any
        # special case here.
        await self.send_json({"type": "connected", "payload": {}})

    async def disconnect(self, code):
        if getattr(self, "group", None):
            await self.channel_layer.group_discard(self.group, self.channel_name)

    async def receive_json(self, content, **kwargs):
        if getattr(self, "participant", None) is None:
            return

        if content.get("type") == CHAT_SEND:
            await self._chat_send(content.get("payload") or {})
            return

        await self.send_json(
            {
                "type": "error",
                "payload": {
                    "code": "read_only",
                    "message": "This socket only carries chat. Post changes to the API.",
                },
            }
        )

    async def fanout(self, event):
        """Group messages arrive here and go straight down the wire."""
        await self.send_json(event["message"])

    async def _chat_send(self, payload):
        failure = await self._write_chat(payload.get("body") or "")
        if failure is not None:
            # Straight back to this one socket. Nobody else's message failed, and
            # a rate limit is not news for the room.
            await self.send_json({"type": "chat.error", "payload": failure})

    @database_sync_to_async
    def _write_chat(self, body):
        """Returns None on success, or the error to hand back to this sender."""
        from .services import chat_message_send

        try:
            chat_message_send(
                # Already proven to be this debate's participant, at connect.
                debate=self.participant.debate,
                participant=self.participant,
                body=body,
            )
        except DomainError as error:
            return {"code": error.code, "message": error.message}
        except ValidationError:
            return {"code": "invalid", "message": "That message cannot be sent."}
        return None

    @database_sync_to_async
    def _participant(self, token):
        if not token:
            return None
        return Participant.objects.filter(
            token=token, debate_id=self.debate_id
        ).first()
