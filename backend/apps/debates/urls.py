from django.urls import path

from . import views

urlpatterns = [
    path("debates/", views.DebateCreateApi.as_view()),
    path("debates/join/", views.DebateJoinApi.as_view()),
    path("debates/<uuid:debate_id>/", views.DebateDetailApi.as_view()),
    path("debates/<uuid:debate_id>/arguments/", views.ArgumentCreateApi.as_view()),
    path("debates/<uuid:debate_id>/start/", views.DebateStartApi.as_view()),
    path("debates/<uuid:debate_id>/end/", views.DebateEndApi.as_view()),
    path("debates/<uuid:debate_id>/chat/", views.ChatListApi.as_view()),
    path("debates/<uuid:debate_id>/chat/<uuid:message_id>/", views.ChatDeleteApi.as_view()),
]
