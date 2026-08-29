from rest_framework import serializers

from .models import Argument, Debate, Participant, Role

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


# --- output --------------------------------------------------------------


class ParticipantOutSerializer(serializers.ModelSerializer):
    class Meta:
        model = Participant
        fields = ["id", "display_name", "role"]


class ArgumentOutSerializer(serializers.ModelSerializer):
    author_name = serializers.CharField(source="participant.display_name", default=None)

    class Meta:
        model = Argument
        fields = ["id", "side", "round_number", "body", "author_name", "created_at"]


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

    class Meta(DebateOutSerializer.Meta):
        fields = DebateOutSerializer.Meta.fields + ["participants", "arguments"]


class SessionSerializer(serializers.Serializer):
    """What a client gets on create or join: who it is, and the key to come back with."""

    debate = DebateDetailSerializer()
    participant = ParticipantOutSerializer()
    token = serializers.CharField()
