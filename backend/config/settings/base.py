"""Settings shared by every environment. Machine-specific values come from .env."""

from pathlib import Path

import dj_database_url
from dotenv import load_dotenv
import os

BASE_DIR = Path(__file__).resolve().parent.parent.parent
REPO_ROOT = BASE_DIR.parent

load_dotenv(REPO_ROOT / ".env")

SECRET_KEY = os.getenv("DJANGO_SECRET_KEY", "dev-only-not-secret")
DEBUG = os.getenv("DJANGO_DEBUG", "1") == "1"
ALLOWED_HOSTS = ["*"] if DEBUG else os.getenv("DJANGO_ALLOWED_HOSTS", "").split(",")

INSTALLED_APPS = [
    # Ahead of staticfiles so runserver speaks ASGI.
    "daphne",
    "channels",
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "rest_framework",
    "corsheaders",
    "django_extensions",
    "django_rq",
    "apps.common",
    "apps.debates",
    "apps.referee",
    "apps.voting",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"
WSGI_APPLICATION = "config.wsgi.application"
ASGI_APPLICATION = "config.asgi.application"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

DATABASES = {
    "default": dj_database_url.parse(
        os.getenv("DATABASE_URL", "postgres://refbot:refbot@localhost:5432/refbot"),
    ),
}

REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379")

# Redis is split by purpose: db 0 channel layer, db 1 cache, db 2 jobs.
CHANNEL_LAYERS = {
    "default": {
        # The pub/sub layer, not channels_redis.core: the core layer's blocking
        # read races its own socket timeout and drops idle sockets every 5s.
        "BACKEND": "channels_redis.pubsub.RedisPubSubChannelLayer",
        "CONFIG": {"hosts": [f"{REDIS_URL}/0"]},
    },
}

CACHES = {
    "default": {
        "BACKEND": "django_redis.cache.RedisCache",
        "LOCATION": f"{REDIS_URL}/1",
    },
}

REST_FRAMEWORK = {
    # request.user is a Participant, not a Django User.
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "apps.common.authentication.ParticipantTokenAuthentication",
    ],
    "DEFAULT_PERMISSION_CLASSES": ["rest_framework.permissions.AllowAny"],
    "EXCEPTION_HANDLER": "apps.common.exception_handler.refbot_exception_handler",
    "UNAUTHENTICATED_USER": None,
}

RQ_QUEUES = {
    "referee": {"URL": f"{REDIS_URL}/2", "DEFAULT_TIMEOUT": 120},
}

# AI referee. Any OpenAI-compatible provider is a different base URL and model.
REFEREE_API_KEY = os.getenv("REFEREE_API_KEY", "")
REFEREE_MODEL = os.getenv("REFEREE_MODEL", "gemini-3.5-flash-lite")
REFEREE_BASE_URL = os.getenv(
    "REFEREE_BASE_URL", "https://generativelanguage.googleapis.com/v1beta/openai/"
)

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

LANGUAGE_CODE = "en-us"
TIME_ZONE = "UTC"
USE_I18N = True
USE_TZ = True

STATIC_URL = "static/"

# The Flutter web dev server picks a new port every run.
CORS_ALLOW_ALL_ORIGINS = DEBUG
