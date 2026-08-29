"""Escape hatch for a machine without Docker: SQLite and in-memory everything.

Run with: python manage.py runserver --settings=config.settings.workshop_offline
"""

from .base import *  # noqa: F403
from .base import BASE_DIR

DEBUG = True

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": BASE_DIR / "db.sqlite3",
    },
}

CACHES = {
    "default": {"BACKEND": "django.core.cache.backends.locmem.LocMemCache"},
}
