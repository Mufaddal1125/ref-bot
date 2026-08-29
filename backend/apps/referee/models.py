from django.db import models


class AnalysisStatus(models.TextChoices):
    PENDING = "pending", "Pending"
    RUNNING = "running", "Running"
    COMPLETE = "complete", "Complete"
    FAILED = "failed", "Failed"


class Analysis(models.Model):
    argument = models.OneToOneField(
        "debates.Argument", related_name="analysis", on_delete=models.CASCADE
    )
    status = models.CharField(
        max_length=16, choices=AnalysisStatus, default=AnalysisStatus.PENDING
    )
    # The validated RefereeAnalysis, stored whole so the schema, the API and the
    # Flutter model stay the same shape end to end.
    result = models.JSONField(null=True, blank=True)
    model = models.CharField(max_length=100, blank=True)
    latency_ms = models.PositiveIntegerField(null=True, blank=True)
    error = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name_plural = "analyses"

    def __str__(self):
        return f"{self.argument} · {self.status}"
