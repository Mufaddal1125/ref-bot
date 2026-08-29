from rest_framework.response import Response
from rest_framework.views import APIView

from apps.common.permissions import IsDebateParticipant, IsModerator
from apps.debates.selectors import debate_get
from apps.debates.serializers import DebateDetailSerializer

from .serializers import VoteCreateSerializer
from .services import debate_close, vote_cast


class VoteCreateApi(APIView):
    permission_classes = [IsDebateParticipant]

    def post(self, request, debate_id):
        # TODO(step 3): validate, call vote_cast, return the debate at 201.
        raise NotImplementedError


class DebateCloseApi(APIView):
    permission_classes = [IsModerator]

    def post(self, request, debate_id):
        # TODO(step 3)
        raise NotImplementedError


def _state(debate_id, request):
    return DebateDetailSerializer(
        debate_get(debate_id), context={"participant": request.user}
    ).data
