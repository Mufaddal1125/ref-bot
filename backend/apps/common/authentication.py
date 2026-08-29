from rest_framework.authentication import BaseAuthentication, get_authorization_header
from rest_framework.exceptions import AuthenticationFailed

from apps.debates.models import Participant


class ParticipantTokenAuthentication(BaseAuthentication):
    """Reads `Authorization: Participant <token>` and puts a Participant on request.user."""

    keyword = "Participant"

    def authenticate(self, request):
        header = get_authorization_header(request).decode()
        prefix = f"{self.keyword} "
        if not header.startswith(prefix):
            return None

        token = header[len(prefix) :].strip()
        participant = (
            Participant.objects.select_related("debate").filter(token=token).first()
        )
        if participant is None:
            raise AuthenticationFailed("Unknown participant token.")
        return participant, token

    def authenticate_header(self, request):
        return self.keyword
