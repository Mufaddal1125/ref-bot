# 🥊 RefBot

A live debate platform, built across four workshop phases: **humans debate → an AI referee analyses → the audience votes**.

Django + DRF + Channels + PostgreSQL + Redis on the back, Flutter on the front.
The product brief is [docs/project-plan.md](docs/project-plan.md).

## Layout

```
backend/    Django project (config/ + apps/)
app/        Flutter client (all platforms, one codebase)
packages/   Local Dart packages the client depends on by path
docs/       Product brief, syllabus map, per-phase facilitator notes
scripts/    dev + checkpoint helpers
```

[docs/syllabus-map.md](docs/syllabus-map.md) maps every course topic to the file and phase
where it is used.

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

## Running it for a room

The three-terminal setup above is for one developer. To put RefBot in front of a
couple of hundred people on the same network, one machine runs everything in Docker:

```powershell
scripts\deploy-local.ps1        # scripts/deploy-local.sh elsewhere
```

That builds the Flutter web client, brings up `docker-compose.deploy.yml`, and prints
the URL — `http://<this machine's LAN IP>`. Everyone opens that address; nobody
installs anything.

| | |
|---|---|
| `caddy` | Serves the Flutter build and proxies `/api`, `/ws`, `/admin`, `/static`. The only published port |
| `backend` | `uvicorn` with 4 worker processes, `config.settings.lan` |
| `worker` | 2 × `rqworker referee` |
| `postgres` `redis` | Own volumes, own project name, no published ports |

One origin serves the client and the API, so there is no CORS, no second port to open,
and the WebSocket is `ws://<same host>/ws/…`. The client is compiled against that
address — rerun the script if the machine's IP changes.

```powershell
scripts\deploy-local.ps1 -Port 8080     # if IIS or http.sys already owns 80
scripts\deploy-local.ps1 -HostIp 192.168.1.20
scripts\deploy-local.ps1 -SkipBuild     # backend-only change
```

Windows Firewall blocks the port for other devices until you allow it once, from an
admin shell — the script prints the exact `New-NetFirewallRule` line.

```bash
docker compose -f docker-compose.deploy.yml logs -f backend worker
docker compose -f docker-compose.deploy.yml down          # add -v to drop the data
```

Secrets live in `.env.deploy`, which the script creates from `.env.deploy.example`
with a fresh `DJANGO_SECRET_KEY`. Put `REFEREE_API_KEY` in it. The dev `.env` and
`docker-compose.yml` are untouched: the two stacks have different project names and
different volumes, so they can both be up at once.

### Sizing

Four ASGI workers and 200 Postgres connections carry a few hundred people comfortably
— WebSockets are cheap, and the referee's Gemini call is the only slow thing, which is
why it is on the queue and not the request. Scale a piece if you need to:

```bash
docker compose -f docker-compose.deploy.yml up -d --scale worker=4
```

## Tests

Every phase ships its tests red in the starter tag and green in the complete tag, on both
sides of the app. They are the fastest way to see how far along you are.

```bash
cd backend && .venv/Scripts/python -m pytest   # the rules
cd app && flutter test                         # the widgets
cd packages/refbot_core && dart test           # the shared package, from phase 5
```

## Phases

Each phase has a starter tag you code from and a completed tag you code to. Both the server
and the client are yours to write: the starter has the models, the generated code and one
worked example of each shape, and a `Placeholder()` wherever a screen or a widget is missing.
Facilitator notes live in `docs/phase-N.md`.

| Phase | Tags | Ends with |
|---|---|---|
| 1 — Human debate | `phase-1-start` → `phase-1-complete` | Two teams debating over REST, with a refresh button |
| 2 — Live | `phase-2-start` → `phase-2-complete` | Channels; the refresh button is deleted |
| 3 — AI referee | `phase-3-start` → `phase-3-complete` | Gemini structured output via an RQ job |
| 4 — Voting | `phase-4-start` → `phase-4-complete` | Audience votes, results update live |
| 5 — Polish & package | `phase-5-start` → `phase-5-complete` | A Dart package, branding, a projector layout, an installable PWA |

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
