from rest_framework.permissions import BasePermission

from apps.debates.models import Role


class IsDebateParticipant(BasePermission):
    """The token must belong to somebody in the debate named in the URL."""

    message = "You have not joined this debate."

    def has_permission(self, request, view):
        participant = request.user
        if participant is None:
            return False
        return str(participant.debate_id) == str(view.kwargs.get("debate_id"))


class IsModerator(IsDebateParticipant):
    message = "Only the moderator can do that."

    def has_permission(self, request, view):
        return super().has_permission(request, view) and request.user.role == Role.MODERATOR
