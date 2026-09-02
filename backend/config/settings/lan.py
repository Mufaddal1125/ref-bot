"""One machine serving a whole room: DEBUG off, static collected, connections held.

Used by docker-compose.deploy.yml behind deploy/Caddyfile, where the client, the
API and the socket all arrive on the same origin.

Run with: DJANGO_SETTINGS_MODULE=config.settings.lan
"""

from .base import *  # noqa: F403
from .base import BASE_DIR, DATABASES, os

DEBUG = False

# Whatever address the room typed is the Host we see; on a LAN the network is
# the boundary, not the header. Narrow it by setting DJANGO_ALLOWED_HOSTS.
ALLOWED_HOSTS = [
    host.strip() for host in os.getenv("DJANGO_ALLOWED_HOSTS", "*").split(",") if host.strip()
]

# Admin forms are the only cross-checked POSTs, and they need the scheme spelled out.
CSRF_TRUSTED_ORIGINS = [
    origin.strip()
    for origin in os.getenv("CSRF_TRUSTED_ORIGINS", "").split(",")
    if origin.strip()
]

# A fresh connection per request is the first thing to fall over at 200 people.
# Each worker process holds up to min(32, cores + 4) of these, one per thread in
# the executor Django's sync views run on — keep Postgres max_connections above
# that times the number of workers.
DATABASES["default"]["CONN_MAX_AGE"] = int(os.getenv("DB_CONN_MAX_AGE", "60"))
DATABASES["default"]["CONN_HEALTH_CHECKS"] = True

STATIC_ROOT = BASE_DIR / "staticfiles"

# Caddy puts the client on the same origin as the API, so browsers never
# preflight. This is here for a native build pointed straight at the backend.
CORS_ALLOW_ALL_ORIGINS = True

LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {"plain": {"format": "{levelname} {name} {message}", "style": "{"}},
    "handlers": {
        "console": {"class": "logging.StreamHandler", "formatter": "plain"},
    },
    "root": {"handlers": ["console"], "level": "INFO"},
}
