from rest_framework.authentication import BaseAuthentication, get_authorization_header
from rest_framework.exceptions import AuthenticationFailed

from apps.debates.models import Participant


class ParticipantTokenAuthentication(BaseAuthentication):
    """Reads `Authorization: Participant <token>` and puts a Participant on request.user."""

    keyword = "Participant"

    def authenticate(self, request):
        # TODO(step 1): read the header, look the Participant up, return (participant, token).
        # Return None when the header is absent so other auth classes get a turn.
        raise NotImplementedError

    def authenticate_header(self, request):
        return self.keyword
