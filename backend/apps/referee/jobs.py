from apps.common.broadcast import broadcast

from .clients import RefereeUnavailable, get_referee_client
from .models import Analysis, AnalysisStatus


def analyze_argument(argument_id) -> None:
    """RQ entrypoint: ask the referee about one argument and save what it says."""
    analysis = Analysis.objects.select_related("argument__debate").get(
        argument_id=argument_id
    )
    argument = analysis.argument
    debate = argument.debate

    analysis.status = AnalysisStatus.RUNNING
    analysis.save(update_fields=["status", "updated_at"])
    _announce(debate)

    try:
        result = get_referee_client().analyze(
            topic=debate.topic,
            history=_history(debate, before=argument),
            argument=argument.body,
        )
    except RefereeUnavailable as error:
        analysis.status = AnalysisStatus.FAILED
        analysis.error = str(error)
    else:
        analysis.status = AnalysisStatus.COMPLETE
        analysis.result = result.analysis.model_dump()
        analysis.model = result.model
        analysis.latency_ms = result.latency_ms
        analysis.error = ""

    analysis.save()
    _announce(debate)


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
