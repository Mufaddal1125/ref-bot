from rest_framework.response import Response
from rest_framework.views import APIView

from apps.common.permissions import IsDebateParticipant, IsModerator

from .selectors import chat_messages_recent, debate_get
from .serializers import (
    ArgumentCreateSerializer,
    ArgumentOutSerializer,
    ChatMessageOutSerializer,
    DebateCreateSerializer,
    DebateDetailSerializer,
    DebateJoinSerializer,
    SessionSerializer,
)
from .services import (
    argument_submit,
    chat_message_delete,
    debate_create,
    debate_end,
    debate_join,
    debate_start,
)


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
        return Response(
            DebateDetailSerializer(debate, context={"participant": request.user}).data
        )


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


class ChatListApi(APIView):
    """The backlog. New messages arrive on the socket; this is what came before."""

    permission_classes = [IsDebateParticipant]

    def get(self, request, debate_id):
        messages = chat_messages_recent(debate_id)
        return Response(ChatMessageOutSerializer(messages, many=True).data)


class ChatDeleteApi(APIView):
    permission_classes = [IsModerator]

    def delete(self, request, debate_id, message_id):
        chat_message_delete(debate=debate_get(debate_id), message_id=message_id)
        return Response(status=204)
