# Phase 4 — Audience voting

**Tags:** `phase-4-start` → `phase-4-complete`

The moderator ends the debate, the room votes from their phones, and the bar on the projector
moves as the votes land.

## What the starter already has

- `Vote` model with its migration, admin, serializer and URLs
- `VoteTally` in Flutter with generated code
- `TallyBar` laid out — the two scores, the bar and the painter are all yours
- `vote_panel.dart` with its class and its fields, and nothing in `build` yet

## Your dial tone

```bash
cd backend && .venv/Scripts/python -m pytest    # 5 voting tests, red
cd app     && flutter test                      # 34 tests, 7 of them red
```

## Steps

| # | File | What |
|---|---|---|
| 1 | `voting/selectors.py` | `vote_tally` — count, then cache for 2s |
| 2 | `voting/services.py` | `vote_cast` — one vote each, invalidate, announce — and `debate_close` |
| 3 | `voting/views.py` | Both endpoints |
| 4 | `debates/serializers.py` | `tally` and `my_vote` on the debate |
| 5 | `core/api_client.dart`, `providers/debate_provider.dart` | `vote`, `close`, and keeping `myVote` |
| 6 | `widgets/tally_bar.dart` | `CustomPainter.paint` — the bar itself |
| 7 | `widgets/tally_bar.dart` | The two scores, and the bar that slides |
| 8 | `widgets/vote_panel.dart`, `screens/debate_screen.dart` | The ballot, the result, and showing it once voting opens |

### Things worth saying out loud

**Steps 1–2 — the cache and its invalidation, together.** The tally is cached for two seconds
so that a room of thirty phones refreshing costs one query instead of thirty. Then every vote
deletes the key. Write step 1 and demo it *before* writing the invalidation: votes visibly lag
by two seconds. Then add the `cache.delete` and watch the lag vanish. Nobody forgets what
cache invalidation is for after seeing it that way round.

Show the key while you are there:

```bash
docker compose exec redis redis-cli -n 1 --scan --pattern '*tally*'
```

Redis is doing three separate jobs in this project — db 0 the channel layer, db 1 this cache,
db 2 the job queue — and this is the moment that becomes concrete.

**Step 4 — `my_vote` and why it is null in a broadcast.** Only a *request* knows who is asking.
A broadcast goes to everyone at once, so it cannot carry a per-person field, and correctly
leaves it null. That is not a bug to work around; it is the difference between a response and
an event.

**Step 5 — so the client keeps it.** `_load()` is the only path that learns `myVote`. A socket
push must not clear it.

**Step 6 — painting.** Everything else in this app is laid out from widgets. Here you take a
`Canvas` and draw: clip a rounded rect, fill `shareA` of the width one colour and the rest the
other. Two rectangles and a clip — and the clip is what makes the ends round, so the widget
tree never needs a `ClipRRect` around it.

**Step 7 — the animation lives outside the painter.** The painter draws whatever number it is
handed and knows nothing about time; `TweenAnimationBuilder` hands it a new `shareA` every
frame, from `0.5` to the real share. Separating them is why the bar can slide without the
painting code growing a controller, a `TickerProvider`, or a `setState`. Write step 6 first and
watch the bar jump between values; add the tween and watch it slide.

**Step 8 — one widget, two jobs, decided by two booleans.** Voting is open while the status is
`voting`; this device has voted when `myVote` is not null. Ballot when both say so, result
otherwise, plus a Close button that only the moderator sees. And the panel outlives the vote:
`voting` *and* `closed` both show it, because the result is the last thing on screen when the
debate is over, not something that disappears when voting shuts.

## Demo

This is the one to do with the actual room.

1. Run the backend on `0.0.0.0:8000` and put your LAN IP and the join code on screen
2. Everyone joins as **Audience** from their phone
3. Two volunteers debate two rounds; the referee analyses each argument
4. Moderator ends the debate
5. **Everyone votes at once.** The bar moves on the projector as it happens
6. Moderator closes voting

If you only demo one thing from the whole workshop, demo step 5.

## What this phase is worth in the syllabus

Caching and its invalidation, a uniqueness constraint in the ORM, one more REST resource
(Module IV); animations, drawing and painting with a `CustomPainter`, conditional layout
(Module VI); state management and application state across a whole room of clients (Module V).

## Reference

```bash
git diff phase-4-start..phase-4-complete --stat
```
