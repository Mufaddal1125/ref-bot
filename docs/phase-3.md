# Phase 3 — The AI referee

**Tags:** `phase-3-start` → `phase-3-complete`

Every argument now gets read by Gemini, which reports back in three fixed categories: claims,
missing context, fallacies. The card says *Referee is thinking…* the instant an argument is
posted, and fills itself in a few seconds later with nobody touching anything.

## The two seams this phase is really about

**Provider seam.** `apps/referee/clients/` is the only place an AI SDK is imported. A client
takes plain strings and returns a `RefereeResult` of Pydantic objects, so `jobs.py`, the model,
the serializer and Flutter never learn who answered. Another OpenAI-compatible provider is a
different `REFEREE_BASE_URL`; one with its own protocol is a new file in that folder.

**Process seam.** The web request returns immediately; the referee call happens in a separate
worker process. The two only meet through Redis — the job queue going out, the channel layer
coming back.

```
POST /arguments/  ─▶ Analysis(PENDING) ─▶ [redis db 2] ─▶ rq worker ─▶ Gemini
                                                              │
     every socket ◀── [redis db 0] ◀── broadcast ◀────────────┘
```

## What the starter already has

- `schemas.py` and `prompts.py`, written in full — do not spend live minutes typing prose
- `clients/base.py`: the `RefereeClient` protocol and `RefereeResult`
- `Analysis` model with its migration, admin, and serializer
- `django-rq` configured on Redis db 2, dashboard at `/django-rq/`
- Flutter: `Analysis` / `RefereeAnalysis` models with their generated code, and `AnalysisCard`
  present with its `_Line` written — the three lists that fill it are yours

## Your dial tone

```bash
cd backend && .venv/Scripts/python -m pytest    # 4 referee tests, red
cd app     && flutter test                      # 25 tests, 9 of them red
```

The nine are `analysis_card_test.dart` and the referee half of `argument_tile_test.dart`. They
pin down every state the card can be in — thinking, failed, finished with findings, finished
with none — which is most of the work of steps 5 and 6 described for you in advance.

This is the AI phase, and four of its six steps are the pipeline itself. Spend the time on
those four — the schema, the parse, the queue and the two seams — and treat the last two as the
window onto them.

## Steps

| # | File | What |
|---|---|---|
| 1 | `referee/clients/gemini.py` | `analyze` — `chat.completions.parse` |
| 2 | `referee/clients/__init__.py` | `get_referee_client` |
| 3 | `referee/jobs.py` | `analyze_argument` — the status machine |
| 4 | `debates/services.py` | `_ask_the_referee` — row now, job on commit |
| 5 | `widgets/analysis_card.dart` | The three categories, one line each |
| 6 | `widgets/argument_tile.dart` | The referee row, and tap to expand |

### Things worth saying out loud

**Step 1 — no hand-written JSON schema.** `.parse()` turns the Pydantic model into a strict
schema itself. Show them: `to_strict_json_schema(RefereeAnalysis)` already carries
`additionalProperties: false` on every object and lists every property in `required`, which is
exactly what strict mode demands and exactly what people get wrong by hand.

**Step 1 — `message.parsed` can be `None`.** A refusal or an off-schema answer lands there.
Saving it would write an empty analysis that looks like "the referee found nothing". Fail loudly
instead.

**Step 4 — `transaction.on_commit`, and this time it really bites.** The worker is a different
process. Enqueue inside the transaction and it can look up a row that has not been committed
yet — a race that passes on your laptop and fails in the room.

**Step 5 — three loops, no `.map().toList()`.** A collection-`for` inside the `children` list is
how Dart builds a list of widgets from a list of data: `for (final f in analysis.fallacies)
_Line(...)`. No temporary list, no `add()`, no spread. The three loops read as the three things
the referee is allowed to say, in the order they matter.

**Step 6 — the tile becomes stateful, and gets three faces.** Pending and running both mean
*thinking*; failed shows the reason, not a shrug; complete shows counts, because a summary the
room can read from the back is worth more than the detail. `AnalysisStatus.isWaiting` already
folds the first two together for you.

**Step 6, again — ephemeral state, in the same file as application state.** Whether one tile is
expanded lives in `setState`. Nobody else needs to know. The debate the tile is drawn from
lives in a provider that every widget watches. Put the two a few lines apart and the difference
stops being abstract. `AnimatedSize` does the unfolding and `AnimatedRotation` turns the
chevron — two widgets, no controller, no `TickerProvider`.

## Running it

Phase 3 needs a fourth terminal:

```bash
python manage.py rqworker referee --worker-class rq.SimpleWorker   # Windows
python manage.py rqworker referee                                  # macOS / Linux
```

RQ's default worker forks, which Windows has no equivalent for. `SimpleWorker` runs the job
in-process instead.

Put `/django-rq/` on screen beside the app. Watching a job appear and drain while the card
fills in makes the queue concrete in a way a diagram does not.

## Demo

1. Post an argument with an obvious fallacy: *"Social media is destroying society because
   everyone knows it's harmful."*
2. The card shows **Referee is thinking…** immediately — that is the `PENDING` row, written
   before the job even runs
3. A few seconds later: `1 🚨  1 ⚠  0 ✓`
4. Tap it. The analysis unfolds
5. Now stop the worker and post another argument. It sits at *thinking* forever. Start the
   worker again and it completes — the queue was holding the job the whole time

Step 5 is worth the thirty seconds. It is the clearest demonstration of what a queue is for.

## Keys

Each student needs their own key from
[aistudio.google.com/apikey](https://aistudio.google.com/apikey) in `.env` as `REFEREE_API_KEY`.
One shared key rate-limits the whole room at once.

With no key the pipeline still runs end to end and every analysis lands in `FAILED` with
`REFEREE_API_KEY is not set in .env`. Useful for checking your wiring before the keys arrive,
and it is the state `argument_tile_test.dart` pins down for you.

## What this phase is worth in the syllabus

AI/ML API integration — the self-learning topic, done properly (Module VI); background work
across a process boundary (Module IV, lab 9); gestures, animations, `map`/collection-`for` over
lists, and ephemeral vs application state (Modules V and VI).

## Reference

```bash
git diff phase-3-start..phase-3-complete --stat
```
