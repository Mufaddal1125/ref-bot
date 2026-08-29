from urllib.parse import parse_qs

from channels.db import database_sync_to_async
from channels.generic.websocket import AsyncJsonWebsocketConsumer

from apps.common.broadcast import group_name

from .models import Participant

CLOSE_UNAUTHORIZED = 4401


class DebateConsumer(AsyncJsonWebsocketConsumer):
    """Read-only. Pushes changes out; changes come in through the REST API."""

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
        # reconnect resyncs without any special case.
        await self.send_json({"type": "connected", "payload": {}})

    async def disconnect(self, code):
        if getattr(self, "group", None):
            await self.channel_layer.group_discard(self.group, self.channel_name)

    async def receive_json(self, content, **kwargs):
        """Nothing arrives here in normal use; the client posts to the API instead."""
        await self.send_json(
            {
                "type": "error",
                "payload": {
                    "code": "read_only",
                    "message": "This socket only sends. Post changes to the API.",
                },
            }
        )

    async def fanout(self, event):
        """Group messages arrive here and go straight down the wire."""
        await self.send_json(event["message"])

    @database_sync_to_async
    def _participant(self, token):
        if not token:
            return None
        return Participant.objects.filter(
            token=token, debate_id=self.debate_id
        ).first()
