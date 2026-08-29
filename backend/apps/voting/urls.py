from django.urls import path

from . import views

urlpatterns = [
    path("debates/<uuid:debate_id>/vote/", views.VoteCreateApi.as_view()),
    path("debates/<uuid:debate_id>/close/", views.DebateCloseApi.as_view()),
]
