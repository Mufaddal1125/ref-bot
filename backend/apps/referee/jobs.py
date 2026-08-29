from apps.common.broadcast import broadcast

from .clients import RefereeUnavailable, get_referee_client
from .models import Analysis, AnalysisStatus


def analyze_argument(argument_id) -> None:
    """RQ entrypoint: ask the referee about one argument and save what it says."""
    # TODO(step 3):
    #   1. Load the Analysis for this argument (select_related pays here).
    #   2. PENDING -> RUNNING, save, and _announce so the spinner appears.
    #   3. get_referee_client().analyze(topic, _history(...), argument.body).
    #   4. RefereeUnavailable -> FAILED with the message. Otherwise COMPLETE with
    #      result.analysis.model_dump(), the model name and the latency.
    #   5. Save and _announce again.
    raise NotImplementedError


def _history(debate, *, before) -> list[str]:
    return [
        f"{a.get_side_display()} (round {a.round_number}): {a.body}"
        for a in debate.arguments.all()
        if a.created_at < before.created_at
    ]


def _announce(debate) -> None:
    from apps.debates.selectors import debate_get
    from apps.debates.serializers import DebateDetailSerializer

    broadcast(debate.id, "debate.updated", DebateDetailSerializer(debate_get(debate.id)).data)
