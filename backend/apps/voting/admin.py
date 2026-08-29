from django.contrib import admin

from .models import Vote


@admin.register(Vote)
class VoteAdmin(admin.ModelAdmin):
    list_display = ["debate", "participant", "choice", "created_at"]
    list_filter = ["choice"]
