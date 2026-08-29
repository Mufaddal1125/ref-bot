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

        # TODO(step 1):
        #   1. Browsers cannot set headers on a WebSocket, so read the token out
        #      of self.scope["query_string"] with parse_qs.
        #   2. No matching participant: accept() and then close(CLOSE_UNAUTHORIZED).
        #      Accepting first is what gives the client a close code it can read
        #      instead of a refused upgrade it cannot tell from a dead server.
        #   3. Otherwise join group_name(self.debate_id) and accept().
        #   4. Send {"type": "connected"} — the client answers it by loading the
        #      debate over HTTP, so a reconnect resyncs with no special case.
        raise NotImplementedError

    async def disconnect(self, code):
        # TODO(step 1): leave the group, if this socket ever joined one.
        raise NotImplementedError

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
        # TODO(step 2): one line.
        raise NotImplementedError

    @database_sync_to_async
    def _participant(self, token):
        if not token:
            return None
        return Participant.objects.filter(
            token=token, debate_id=self.debate_id
        ).first()
