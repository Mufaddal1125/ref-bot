from django.db import transaction

from apps.common.errors import Conflict, Forbidden, NotFound

from .models import Argument, Debate, DebateStatus, Participant, Role, Side

ROLE_TO_SIDE = {Role.TEAM_A: Side.TEAM_A, Role.TEAM_B: Side.TEAM_B}


@transaction.atomic
def debate_create(*, topic: str, display_name: str) -> tuple[Debate, Participant]:
    """Open a debate and make its creator the moderator."""
    # TODO(step 2): create the Debate, then its moderator Participant.
    raise NotImplementedError


@transaction.atomic
def debate_join(*, join_code: str, display_name: str, role: str) -> tuple[Debate, Participant]:
    # TODO(step 2): find the debate by code (case-insensitive), refuse a second
    # moderator, then create the Participant.
    raise NotImplementedError


@transaction.atomic
def argument_submit(*, debate: Debate, participant: Participant, body: str) -> Argument:
    """Record an argument and hand the turn to the other side."""
    # TODO(step 3): the heart of phase 1.
    #   1. Re-read the debate with select_for_update() — two teammates can submit at once.
    #   2. Refuse unless the debate is ACTIVE.
    #   3. Map the participant's role to a Side; refuse anyone who has none.
    #   4. Refuse when it is not that side's turn.
    #   5. Create the Argument at the current round.
    #   6. Hand over: A -> B, or B -> A and the round advances.
    raise NotImplementedError


@transaction.atomic
def debate_start(*, debate: Debate) -> Debate:
    # TODO(step 2): LOBBY -> ACTIVE, and refuse anything else.
    raise NotImplementedError


@transaction.atomic
def debate_end(*, debate: Debate) -> Debate:
    # TODO(step 2): ACTIVE -> VOTING, and refuse anything else.
    raise NotImplementedError
