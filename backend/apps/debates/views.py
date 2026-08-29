from rest_framework.response import Response
from rest_framework.views import APIView

from apps.common.permissions import IsDebateParticipant, IsModerator

from .selectors import debate_get
from .serializers import (
    ArgumentCreateSerializer,
    ArgumentOutSerializer,
    DebateCreateSerializer,
    DebateDetailSerializer,
    DebateJoinSerializer,
    SessionSerializer,
)
from .services import argument_submit, debate_create, debate_end, debate_join, debate_start


def _session(debate, participant) -> Response:
    payload = SessionSerializer(
        {"debate": debate, "participant": participant, "token": participant.token}
    ).data
    return Response(payload, status=201)


class DebateCreateApi(APIView):
    def post(self, request):
        # TODO(step 4): validate with DebateCreateSerializer, call debate_create,
        # return _session(...). Every view below follows this same three-line shape.
        raise NotImplementedError


class DebateJoinApi(APIView):
    def post(self, request):
        # TODO(step 4)
        raise NotImplementedError


class DebateDetailApi(APIView):
    permission_classes = [IsDebateParticipant]

    def get(self, request, debate_id):
        # TODO(step 4)
        raise NotImplementedError


class ArgumentCreateApi(APIView):
    permission_classes = [IsDebateParticipant]

    def post(self, request, debate_id):
        # TODO(step 4)
        raise NotImplementedError


class DebateStartApi(APIView):
    permission_classes = [IsModerator]

    def post(self, request, debate_id):
        # TODO(step 4)
        raise NotImplementedError


class DebateEndApi(APIView):
    permission_classes = [IsModerator]

    def post(self, request, debate_id):
        # TODO(step 4)
        raise NotImplementedError
