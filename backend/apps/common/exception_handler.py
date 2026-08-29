from rest_framework.response import Response
from rest_framework.views import exception_handler

from .errors import DomainError


def refbot_exception_handler(exc, context):
    """Give every failure one shape, so the client parses one thing."""
    # TODO(step 1): a DomainError becomes {"code", "message"} at exc.status_code.
    # Anything DRF already handles keeps its status but gets the same two keys,
    # with serializer errors kept under "fields".
    raise NotImplementedError
