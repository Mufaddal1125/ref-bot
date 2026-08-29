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
        started = time.monotonic()
        try:
            completion = self._client.chat.completions.parse(
                model=settings.REFEREE_MODEL,
                messages=build_messages(topic=topic, history=history, argument=argument),
                response_format=RefereeAnalysis,
                temperature=0.2,
            )
        except OpenAIError as error:
            raise RefereeUnavailable(str(error)) from error

        message = completion.choices[0].message
        # parse() returns None when the model refuses or answers off-schema.
        if message.parsed is None:
            raise RefereeUnavailable(message.refusal or "The referee returned nothing usable.")

        return RefereeResult(
            analysis=message.parsed,
            model=completion.model,
            latency_ms=int((time.monotonic() - started) * 1000),
        )
