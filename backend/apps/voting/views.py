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
        payload = VoteCreateSerializer(data=request.data)
        payload.is_valid(raise_exception=True)
        vote_cast(
            debate=debate_get(debate_id),
            participant=request.user,
            **payload.validated_data,
        )
        return Response(_state(debate_id, request), status=201)


class DebateCloseApi(APIView):
    permission_classes = [IsModerator]

    def post(self, request, debate_id):
        debate_close(debate=debate_get(debate_id))
        return Response(_state(debate_id, request))


def _state(debate_id, request):
    return DebateDetailSerializer(
        debate_get(debate_id), context={"participant": request.user}
    ).data
