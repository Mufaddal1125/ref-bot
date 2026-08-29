from rest_framework.response import Response
from rest_framework.views import exception_handler

from .errors import DomainError


def refbot_exception_handler(exc, context):
    """Give every failure one shape, so the client parses one thing."""
    if isinstance(exc, DomainError):
        return Response(
            {"code": exc.code, "message": exc.message},
            status=exc.status_code,
        )

    response = exception_handler(exc, context)
    if response is None:
        return None

    detail = response.data
    if isinstance(detail, dict) and "detail" in detail:
        response.data = {"code": "error", "message": str(detail["detail"])}
    else:
        # Serializer validation: keep the per-field errors alongside the summary.
        response.data = {
            "code": "invalid",
            "message": "That input is not valid.",
            "fields": detail,
        }
    return response
