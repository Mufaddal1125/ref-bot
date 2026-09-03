from django.contrib import admin

from .models import Argument, ChatMessage, Debate, Participant


@admin.register(Debate)
class DebateAdmin(admin.ModelAdmin):
    list_display = ["join_code", "topic", "status", "current_side", "current_round"]
    list_filter = ["status"]


@admin.register(Participant)
class ParticipantAdmin(admin.ModelAdmin):
    list_display = ["display_name", "role", "debate"]
    list_filter = ["role"]


@admin.register(Argument)
class ArgumentAdmin(admin.ModelAdmin):
    list_display = ["debate", "side", "round_number", "created_at"]
    list_filter = ["side"]


@admin.register(ChatMessage)
class ChatMessageAdmin(admin.ModelAdmin):
    list_display = ["debate", "author_name", "author_role", "created_at", "deleted_at"]
    list_filter = ["author_role"]
