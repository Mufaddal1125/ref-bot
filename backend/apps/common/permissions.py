from rest_framework.permissions import BasePermission

from apps.debates.models import Role


class IsDebateParticipant(BasePermission):
    """The token must belong to somebody in the debate named in the URL."""

    message = "You have not joined this debate."

    def has_permission(self, request, view):
        # TODO(step 1): compare request.user.debate_id with view.kwargs["debate_id"].
        raise NotImplementedError


class IsModerator(IsDebateParticipant):
    message = "Only the moderator can do that."

    def has_permission(self, request, view):
        # TODO(step 1): a participant of this debate, whose role is MODERATOR.
        raise NotImplementedError
