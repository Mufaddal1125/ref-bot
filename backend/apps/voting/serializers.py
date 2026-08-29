from rest_framework import serializers

from apps.debates.models import Side


class VoteCreateSerializer(serializers.Serializer):
    choice = serializers.ChoiceField(choices=Side.choices)
