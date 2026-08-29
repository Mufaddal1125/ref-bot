import time

from django.conf import settings
from openai import OpenAI, OpenAIError

from ..prompts import build_messages
from ..schemas import RefereeAnalysis
from .base import RefereeResult, RefereeUnavailable


class GeminiRefereeClient:
    """Gemini through Google's OpenAI-compatible endpoint. The only file importing the SDK."""

    def __init__(self):
        self._client = OpenAI(
            api_key=settings.REFEREE_API_KEY,
            base_url=settings.REFEREE_BASE_URL,
            timeout=30,
            max_retries=2,
        )

    def analyze(self, *, topic: str, history: list[str], argument: str) -> RefereeResult:
        # TODO(step 1): chat.completions.parse with response_format=RefereeAnalysis.
        # .parse() builds the strict JSON schema out of the Pydantic model, so
        # write no schema by hand.
        #
        # Two things to get right:
        #   - message.parsed is None when the model refuses or answers off-schema.
        #     Raise RefereeUnavailable rather than saving an empty result.
        #   - An OpenAIError means the provider is unreachable. Same exception,
        #     so nothing upstream learns which provider failed.
        raise NotImplementedError
