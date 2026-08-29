import pytest

from apps.debates.models import Role
from apps.debates.services import argument_submit, debate_create, debate_join, debate_start
from apps.referee.clients import RefereeResult, RefereeUnavailable
from apps.referee.jobs import analyze_argument
from apps.referee.models import Analysis, AnalysisStatus
from apps.referee.schemas import Fallacy, RefereeAnalysis

pytestmark = pytest.mark.django_db


class StubClient:
    """Stands in at the protocol boundary, so no test needs a network."""

    def __init__(self, analysis=None, error=None):
        self._analysis = analysis
        self._error = error

    def analyze(self, *, topic, history, argument):
        if self._error:
            raise RefereeUnavailable(self._error)
        return RefereeResult(analysis=self._analysis, model="stub-1", latency_ms=12)


@pytest.fixture
def argument():
    debate, _ = debate_create(topic="Cats beat dogs", display_name="Mo")
    _, team_a = debate_join(join_code=debate.join_code, display_name="A", role=Role.TEAM_A)
    debate_start(debate=debate)
    debate.refresh_from_db()
    return argument_submit(debate=debate, participant=team_a, body="Everyone knows cats win.")


def test_submitting_queues_a_pending_analysis(argument):
    assert argument.analysis.status == AnalysisStatus.PENDING


def test_a_good_answer_is_stored_whole(argument, monkeypatch):
    analysis = RefereeAnalysis(
        claims=[],
        missing_context=[],
        fallacies=[Fallacy(name="Appeal to common belief", explanation="'Everyone knows'.")],
    )
    monkeypatch.setattr(
        "apps.referee.jobs.get_referee_client", lambda: StubClient(analysis=analysis)
    )

    analyze_argument(argument.id)

    saved = Analysis.objects.get(argument=argument)
    assert saved.status == AnalysisStatus.COMPLETE
    assert saved.model == "stub-1"
    assert saved.result["fallacies"][0]["name"] == "Appeal to common belief"


def test_an_unavailable_referee_fails_loudly(argument, monkeypatch):
    monkeypatch.setattr(
        "apps.referee.jobs.get_referee_client",
        lambda: StubClient(error="REFEREE_API_KEY is not set in .env"),
    )

    analyze_argument(argument.id)

    saved = Analysis.objects.get(argument=argument)
    assert saved.status == AnalysisStatus.FAILED
    assert "REFEREE_API_KEY" in saved.error
    assert saved.result is None


def test_history_stops_before_the_argument_under_review(argument, monkeypatch):
    seen = {}

    class Recorder(StubClient):
        def analyze(self, *, topic, history, argument):
            seen["history"] = history
            seen["argument"] = argument
            return super().analyze(topic=topic, history=history, argument=argument)

    monkeypatch.setattr(
        "apps.referee.jobs.get_referee_client",
        lambda: Recorder(
            analysis=RefereeAnalysis(claims=[], missing_context=[], fallacies=[])
        ),
    )

    analyze_argument(argument.id)

    assert seen["history"] == []
    assert seen["argument"] == "Everyone knows cats win."
