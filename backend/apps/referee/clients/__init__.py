from django.conf import settings

from .base import RefereeClient, RefereeResult, RefereeUnavailable
from .gemini import GeminiRefereeClient

__all__ = ["RefereeClient", "RefereeResult", "RefereeUnavailable", "get_referee_client"]


def get_referee_client() -> RefereeClient:
    """The one place a provider is chosen. A second provider is a second file here."""
    # TODO(step 2): refuse clearly when REFEREE_API_KEY is missing, then hand
    # back a GeminiRefereeClient.
    raise NotImplementedError
