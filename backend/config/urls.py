from django.contrib import admin
from django.http import HttpResponse
from django.urls import include, path

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/", include("apps.debates.urls")),
    path("api/", include("apps.voting.urls")),
    path("django-rq/", include("django_rq.urls")),
    # Container healthcheck: no database, no template, just proof the process is up.
    path("healthz", lambda _request: HttpResponse("ok")),
]
