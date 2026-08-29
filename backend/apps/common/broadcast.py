from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer


def group_name(debate_id) -> str:
    return f"debate.{debate_id}"


def broadcast(debate_id, type_: str, payload: dict) -> None:
    """Push one event to everyone watching a debate, from synchronous code."""
    async_to_sync(get_channel_layer().group_send)(
        group_name(debate_id),
        {"type": "fanout", "message": {"type": type_, "payload": payload}},
    )
