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
        payload = DebateCreateSerializer(data=request.data)
        payload.is_valid(raise_exception=True)
        debate, moderator = debate_create(**payload.validated_data)
        return _session(debate, moderator)


class DebateJoinApi(APIView):
    def post(self, request):
        payload = DebateJoinSerializer(data=request.data)
        payload.is_valid(raise_exception=True)
        debate, participant = debate_join(**payload.validated_data)
        return _session(debate, participant)


class DebateDetailApi(APIView):
    permission_classes = [IsDebateParticipant]

    def get(self, request, debate_id):
        debate = debate_get(debate_id)
        return Response(DebateDetailSerializer(debate).data)


class ArgumentCreateApi(APIView):
    permission_classes = [IsDebateParticipant]

    def post(self, request, debate_id):
        payload = ArgumentCreateSerializer(data=request.data)
        payload.is_valid(raise_exception=True)
        argument = argument_submit(
            debate=debate_get(debate_id),
            participant=request.user,
            **payload.validated_data,
        )
        return Response(ArgumentOutSerializer(argument).data, status=201)


class DebateStartApi(APIView):
    permission_classes = [IsModerator]

    def post(self, request, debate_id):
        debate = debate_start(debate=debate_get(debate_id))
        return Response(DebateDetailSerializer(debate).data)


class DebateEndApi(APIView):
    permission_classes = [IsModerator]

    def post(self, request, debate_id):
        debate = debate_end(debate=debate_get(debate_id))
        return Response(DebateDetailSerializer(debate).data)
