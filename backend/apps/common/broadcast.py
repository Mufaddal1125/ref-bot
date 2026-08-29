from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer


def group_name(debate_id) -> str:
    return f"debate.{debate_id}"


def broadcast(debate_id, type_: str, payload: dict) -> None:
    """Push one event to everyone watching a debate, from synchronous code."""
    # TODO(step 2): group_send the envelope {"type": ..., "payload": ...} to
    # group_name(debate_id). The channel layer is async and callers are not,
    # so this needs async_to_sync. The consumer method that receives it is
    # named by the "type" key of the outer dict.
    raise NotImplementedError
