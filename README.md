# 🥊 RefBot

A live debate platform, built across four workshop phases: **humans debate → an AI referee analyses → the audience votes**.

Django + DRF + Channels + PostgreSQL + Redis on the back, Flutter on the front.
The product brief is [docs/project-plan.md](docs/project-plan.md).

## Layout

```
backend/   Django project (config/ + apps/)
app/       Flutter client (all platforms, one codebase)
docs/      Product brief, API contract, per-phase facilitator notes
scripts/   dev + checkpoint helpers
```

## Prerequisites

Python 3.12 · Flutter (stable) · Docker Desktop · Git

## Setup

Run this once, before the workshop. It is the part that takes time.

```bash
cp .env.example .env

# infrastructure
docker compose up -d

# backend
cd backend
python -m venv .venv
.venv/Scripts/activate          # Windows;  source .venv/bin/activate  elsewhere
pip install -r requirements.txt
python manage.py migrate

# client
cd ../app
flutter pub get
```

Postgres and Redis deliberately sit on **5442** and **6389**, not their defaults, so RefBot
does not fight anything already running on 5432 or 6379. If those clash too, change
`POSTGRES_PORT` / `REDIS_PORT` in `.env` and the matching URLs beside them.

## Running

Three terminals:

```bash
# 1. infrastructure
docker compose up

# 2. backend  (from backend/, venv active)
python manage.py runserver

# 3. client  (from app/)
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

From phase 3 there is a fourth, the job worker:

```bash
python manage.py rqworker referee --worker-class rq.SimpleWorker   # Windows
python manage.py rqworker referee                                  # macOS / Linux
```

`rq.SimpleWorker` runs jobs in-process; the default worker forks, which Windows has no equivalent for.

### Other devices

`API_BASE_URL` is the only thing that changes per device — there is no platform-specific code.

| Target | Value |
|---|---|
| Web, Windows, macOS, Linux | `http://localhost:8000` |
| Android emulator | `http://10.0.2.2:8000` |
| A phone on your LAN | `http://<your-lan-ip>:8000` |

For a phone, run the backend on all interfaces and open the port:

```bash
python manage.py runserver 0.0.0.0:8000
```

## Phases

Each phase has a starter tag you code from and a completed tag you code to.
Facilitator notes live in `docs/phase-N.md`.

| Phase | Tags | Ends with |
|---|---|---|
| 1 — Human debate | `phase-1-start` → `phase-1-complete` | Two teams debating over REST, with a refresh button |
| 2 — Live | `phase-2-start` → `phase-2-complete` | Channels; the refresh button is deleted |
| 3 — AI referee | `phase-3-start` → `phase-3-complete` | Gemini structured output via an RQ job |
| 4 — Voting | `phase-4-start` → `phase-4-complete` | Audience votes, results update live |

To see exactly what a phase asks you to write:

```bash
git diff phase-2-start..phase-2-complete --stat
```

To jump to a checkpoint, keeping your own work stashed:

```bash
scripts/checkpoint.ps1 phase-2-start     # or scripts/checkpoint.sh
```

## The AI referee

Phase 3 calls **Gemini through the OpenAI SDK**, pointed at Google's OpenAI-compatible
endpoint. Get a key at [aistudio.google.com/apikey](https://aistudio.google.com/apikey) and
put it in `.env` as `REFEREE_API_KEY`.

Provider lives behind one seam: `apps/referee/clients/` is the only place the SDK is
imported, and it hands back plain Pydantic objects. Any other OpenAI-compatible provider is
just `REFEREE_BASE_URL` and `REFEREE_MODEL`; one that speaks its own protocol is a new file
in `clients/`.
