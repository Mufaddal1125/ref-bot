from rest_framework import serializers

from apps.referee.serializers import AnalysisOutSerializer

from .models import Argument, ChatMessage, Debate, Participant, Role

# --- input ---------------------------------------------------------------


class DebateCreateSerializer(serializers.Serializer):
    topic = serializers.CharField(max_length=500)
    display_name = serializers.CharField(max_length=40)


class DebateJoinSerializer(serializers.Serializer):
    join_code = serializers.CharField(max_length=6)
    display_name = serializers.CharField(max_length=40)
    role = serializers.ChoiceField(choices=Role.choices)


class ArgumentCreateSerializer(serializers.Serializer):
    body = serializers.CharField(max_length=4000)


class ChatMessageCreateSerializer(serializers.Serializer):
    """Also used off the socket, so it has to stand on its own without a request."""

    body = serializers.CharField(max_length=500, allow_blank=False, trim_whitespace=True)


# --- output --------------------------------------------------------------


class ParticipantOutSerializer(serializers.ModelSerializer):
    class Meta:
        model = Participant
        fields = ["id", "display_name", "role"]


class ArgumentOutSerializer(serializers.ModelSerializer):
    author_name = serializers.CharField(source="participant.display_name", default=None)
    analysis = AnalysisOutSerializer(read_only=True)

    class Meta:
        model = Argument
        fields = [
            "id",
            "side",
            "round_number",
            "body",
            "author_name",
            "created_at",
            "analysis",
        ]


class ChatMessageOutSerializer(serializers.ModelSerializer):
    is_deleted = serializers.BooleanField(read_only=True)
    body = serializers.SerializerMethodField()

    class Meta:
        model = ChatMessage
        fields = [
            "id",
            "author_name",
            "author_role",
            "body",
            "created_at",
            "is_deleted",
        ]

    def get_body(self, message) -> str:
        """A removed message keeps its row and its place, but not its words."""
        return "" if message.is_deleted else message.body


class DebateOutSerializer(serializers.ModelSerializer):
    class Meta:
        model = Debate
        fields = [
            "id",
            "topic",
            "join_code",
            "status",
            "current_side",
            "current_round",
            "created_at",
        ]


class DebateDetailSerializer(DebateOutSerializer):
    participants = ParticipantOutSerializer(many=True, read_only=True)
    arguments = ArgumentOutSerializer(many=True, read_only=True)
    tally = serializers.SerializerMethodField()
    my_vote = serializers.SerializerMethodField()

    class Meta(DebateOutSerializer.Meta):
        fields = DebateOutSerializer.Meta.fields + [
            "participants",
            "arguments",
            "tally",
            "my_vote",
        ]

    def get_tally(self, debate):
        from apps.voting.selectors import vote_tally

        return vote_tally(debate)

    def get_my_vote(self, debate):
        """Only a request knows who is asking; a broadcast leaves this null."""
        participant = self.context.get("participant")
        if participant is None:
            return None
        vote = next(
            (v for v in debate.votes.all() if v.participant_id == participant.id), None
        )
        return vote.choice if vote else None


class SessionSerializer(serializers.Serializer):
    """What a client gets on create or join: who it is, and the key to come back with."""

    debate = DebateDetailSerializer()
    participant = ParticipantOutSerializer()
    token = serializers.CharField()
