import uuid

from django.db import models

from apps.debates.models import Side


class Vote(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    debate = models.ForeignKey("debates.Debate", related_name="votes", on_delete=models.CASCADE)
    participant = models.ForeignKey("debates.Participant", on_delete=models.CASCADE)
    choice = models.CharField(max_length=16, choices=Side)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["debate", "participant"], name="one_vote_per_participant"
            ),
        ]

    def __str__(self):
        return f"{self.participant} -> {self.get_choice_display()}"
