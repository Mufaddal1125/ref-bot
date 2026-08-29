from rest_framework import serializers

from .models import Analysis


class AnalysisOutSerializer(serializers.ModelSerializer):
    class Meta:
        model = Analysis
        fields = ["status", "result", "model", "error"]
