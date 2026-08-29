# Phase 1 — Human debate over REST

**Tags:** `phase-1-start` → `phase-1-complete`

At the end of this phase two teams can hold a full debate through the browser, taking turns,
with a shared history. There is a Refresh button. That button is the point: phase 2 deletes it.

## What the starter already has

- Postgres and Redis in `docker-compose.yml`, settings split into `base` / `dev` / `workshop_offline`
- All three models with their migration committed — nobody debugs `makemigrations` live
- Serializers, selectors, URLs, admin registrations
- Every Flutter model with its generated `.g.dart` beside it, and the router's four routes
- The home, create and join screens, the theme, and the argument composer — forms and colours,
  written out so the live time goes on the parts worth explaining
- Two worked examples: `ApiClient.createDebate` / `fetchDebate`, and `DebateProvider._run`

The turn banner, the argument tile and the debate history are `Placeholder()`s. Those three
crossed boxes are the client half of this phase.

## Your dial tone

```bash
cd backend && .venv/Scripts/python -m pytest    # 16 tests, all red
cd app     && flutter test                      # 14 tests, 8 of them red
```

Phase 1 is done when both are green and the app runs. Anyone who falls behind can run either
one to see exactly where they are.

## Steps

| # | File | What |
|---|---|---|
| 1 | `apps/common/` | One shape for every error, `Authorization: Participant <token>` → `request.user`, and the two permission classes |
| 2 | `apps/debates/services.py` | `debate_create`, `debate_join`, `debate_start`, `debate_end` |
| 3 | `apps/debates/services.py` | **`argument_submit`** — the turn machine |
| 4 | `apps/debates/views.py` | The six endpoints, each one thin |
| 5 | `core/api_client.dart` | `joinDebate`, `submitArgument`, `startDebate`, `endDebate` |
| 6 | `providers/`, `core/router.dart` | Keep the session, act on the debate, guard the routes |
| 7 | `widgets/turn_banner.dart` | Whose turn it is, as one switch expression |
| 8 | `screens/debate_screen.dart`, `widgets/argument_tile.dart` | The history: a `ListView.builder` of tiles |

Four steps of rules, four of the app around them. A working turn machine nobody can see is not
a demo.

### Step 3 is the one to slow down on

- `select_for_update()` — two teammates can hit submit in the same instant, and the turn
  counter is the thing they would corrupt.
- The round advances on Team B's turn, not Team A's. One round is a pair of arguments.

### Step 4 — why the views are dull

Six endpoints, none of them longer than ten lines: validate with a serializer, call one
service, return one serializer. Every decision already happened in step 2 or 3. A view that
grows past ten lines has a service hiding inside it.

### Step 6 — one place that owns state

`SessionProvider` holds who this device is and writes it to `SharedPreferences`, so a browser
refresh does not sign you out. `DebateProvider` holds the debate and runs every action through
`_run`, so loading and errors live in one place. The router's `redirect` reads the first of
those: with a session, an entry route goes straight to the debate; without one, everything else
goes home. This is MVVM — the widgets you write in steps 7 and 8 hold no logic at all.

### Step 7 — a switch expression, not a ladder of ifs

Five statuses, one of them split by a `when` guard, producing the text and its colour together
as a `(String, Color?)` record. Cover all five and Dart stops asking for a default case — which
means adding a sixth status later becomes a compile error instead of a blank banner. The colour
comes from `sideColor()`, already in `core/theme.dart`, so Team A looks like Team A in the
banner, on the tile, on the ballot and on the result bar.

### Step 8 — `.builder`, not a `Column`

A `Column` of tiles builds every argument ever made, on every frame, whether or not it is on
screen. `ListView.builder` builds the rows it can see. The debate is short today and long in
the demo.

## Demo

Three browser windows: moderator, Team A, Team B.

1. Moderator creates a debate, reads the join code out
2. Both teams join with it
3. Moderator starts
4. Team A argues → **nothing happens in the other windows until you press Refresh**
5. Team B tries to argue out of turn → a clear 409
6. Two full rounds, then the moderator ends it

Leave step 4 hanging for a moment. Everyone in the room should want the Refresh button gone
before you tell them it is what phase 2 is for.

## What this phase is worth in the syllabus

REST, ORM, token authentication and role-based access (Module IV, lab 1 / 6 / 7 / 8); MVVM,
widgets, layout widgets, lists, navigation and routing, state management, Dart switch
expressions and null safety (Module V, lab 11 / 12 / 13); styles and REST access from the
client (Module VI).

## Reference

```bash
git diff phase-1-start..phase-1-complete --stat   # what the phase asks for
git diff phase-1-start..phase-1-complete          # the answers
```
