from dataclasses import dataclass
from typing import Protocol

from ..schemas import RefereeAnalysis


class RefereeUnavailable(Exception):
    """The provider could not be reached, or answered with nothing usable."""


@dataclass(frozen=True)
class RefereeResult:
    analysis: RefereeAnalysis
    model: str
    latency_ms: int


class RefereeClient(Protocol):
    """Plain arguments in, domain objects out. No SDK type crosses this line."""

    def analyze(
        self, *, topic: str, history: list[str], argument: str
    ) -> RefereeResult: ...
