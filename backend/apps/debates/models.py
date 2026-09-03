import secrets
import uuid

from django.db import models

# No I, L, O or U: nobody misreads a code they are typing off a projector.
JOIN_CODE_ALPHABET = "ABCDEFGHJKMNPQRSTVWXYZ23456789"


class Side(models.TextChoices):
    TEAM_A = "team_a", "Team A"
    TEAM_B = "team_b", "Team B"


class Role(models.TextChoices):
    MODERATOR = "moderator", "Moderator"
    TEAM_A = "team_a", "Team A"
    TEAM_B = "team_b", "Team B"
    AUDIENCE = "audience", "Audience"


class DebateStatus(models.TextChoices):
    LOBBY = "lobby", "Lobby"
    ACTIVE = "active", "Active"
    VOTING = "voting", "Voting"
    CLOSED = "closed", "Closed"


def generate_join_code() -> str:
    return "".join(secrets.choice(JOIN_CODE_ALPHABET) for _ in range(6))


def generate_token() -> str:
    return secrets.token_urlsafe(24)


class Debate(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    topic = models.TextField()
    join_code = models.CharField(
        max_length=6, unique=True, db_index=True, default=generate_join_code
    )
    status = models.CharField(max_length=16, choices=DebateStatus, default=DebateStatus.LOBBY)
    current_side = models.CharField(max_length=16, choices=Side, default=Side.TEAM_A)
    current_round = models.PositiveIntegerField(default=1)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.join_code} · {self.topic[:40]}"


class Participant(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    debate = models.ForeignKey(Debate, related_name="participants", on_delete=models.CASCADE)
    display_name = models.CharField(max_length=40)
    role = models.CharField(max_length=16, choices=Role)
    token = models.CharField(max_length=32, unique=True, db_index=True, default=generate_token)
    created_at = models.DateTimeField(auto_now_add=True)
    last_seen_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["created_at"]

    def __str__(self):
        return f"{self.display_name} ({self.get_role_display()})"

    @property
    def is_authenticated(self) -> bool:
        """DRF asks request.user this; a Participant stands in for a Django User."""
        return True


class Argument(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    debate = models.ForeignKey(Debate, related_name="arguments", on_delete=models.CASCADE)
    participant = models.ForeignKey(Participant, null=True, on_delete=models.SET_NULL)
    side = models.CharField(max_length=16, choices=Side)
    round_number = models.PositiveIntegerField()
    body = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["created_at"]
        constraints = [
            models.UniqueConstraint(
                fields=["debate", "side", "round_number"],
                name="one_argument_per_side_per_round",
            ),
        ]

    def __str__(self):
        return f"{self.get_side_display()} round {self.round_number}"


class ChatMessage(models.Model):
    """A line in the room's side-chat. Anyone may write one, at any point."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    debate = models.ForeignKey(Debate, related_name="chat_messages", on_delete=models.CASCADE)
    participant = models.ForeignKey(Participant, null=True, on_delete=models.SET_NULL)

    # Copied at write time rather than read off the participant. The sender can
    # leave, and a transcript with anonymous holes in it reads worse than one
    # that still remembers who said what.
    author_name = models.CharField(max_length=40)
    author_role = models.CharField(max_length=16, choices=Role)

    body = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    # Soft, so a removal shows as a removal. Deleting the row would leave a
    # silent gap that reads, to everyone who saw the message, like a bug.
    deleted_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["created_at"]
        indexes = [models.Index(fields=["debate", "created_at"])]

    def __str__(self):
        return f"{self.author_name}: {self.body[:40]}"

    @property
    def is_deleted(self) -> bool:
        return self.deleted_at is not None
