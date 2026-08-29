from django.urls import path

from apps.debates.consumers import DebateConsumer

websocket_urlpatterns = [
    path("ws/debate/<uuid:debate_id>/", DebateConsumer.as_asgi()),
]
