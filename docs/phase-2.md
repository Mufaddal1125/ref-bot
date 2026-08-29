# Phase 2 — Live, over WebSockets

**Tags:** `phase-2-start` → `phase-2-complete`

Phase 1 ended with a Refresh button. This phase deletes it. By the end, an argument posted in
one window lands in every other window instantly, scrolls itself into view, and killing the
server produces a `Reconnecting…` banner that clears itself when the server comes back.

## The rule that shapes this phase

**The socket only ever sends. Every change still goes to the REST API.**

```
client ──POST /api/…──▶ service ──on_commit──▶ broadcast ──▶ every socket
                          │
                          └──── 409 / 403 straight back to the caller
```

So a rejected argument is an HTTP error the one person who made it sees, and a successful one
is a broadcast everybody sees. Nothing needs to decide which failures to fan out and which to
keep private — the transport already answers that.

It also means the API you built in phase 1 does not change at all, and the socket has no
authorisation logic of its own to keep in step with the permission classes.

## What the starter already has

Everything from phase 1, still working. On top of that, dormant scaffolding:

- `channels` and `daphne` installed and in `INSTALLED_APPS`, so `runserver` already speaks ASGI
- `CHANNEL_LAYERS` pointed at Redis db 0
- `config/asgi.py` and `config/routing.py`, complete
- `consumers.py` and `common/broadcast.py`, stubbed
- `models/server_event.dart` complete, and `core/debate_socket.dart` with `connect` written for you
- the history lifted out of `_DebateBody` into a `_History` widget of its own, stateful, with
  its `ScrollController` created and disposed — only the following is missing

## Your dial tone

There are no new tests this phase: a socket is not a thing a widget test can hold. The
fourteen from phase 1 stay green throughout, and the demo below is the real check.

```bash
cd app && flutter test    # 14 tests, still green
```

## Steps

| # | File | What |
|---|---|---|
| 1 | `consumers.py` | `connect` — token from the query string, join the group, accept — and `disconnect` |
| 2 | `common/broadcast.py`, `consumers.py` | `broadcast` — `async_to_sync` group_send — and the one-line `fanout` |
| 3 | `debates/services.py` | `_announce`, called from the three mutating services |
| 4 | `core/debate_socket.dart` | Backoff, and stop retrying a bad token |
| 5 | `providers/debate_provider.dart` | Socket lifecycle and event dispatch |
| 6 | `screens/debate_screen.dart` | **Delete the Refresh button.** Connect on mount, disconnect on dispose |
| 7 | `screens/debate_screen.dart`, `widgets/argument_composer.dart` | The `Reconnecting…` banner, the error banner, and a composer that refuses while the socket is down |
| 8 | `screens/debate_screen.dart` | `_History` — follow the newest argument down |

### Things worth saying out loud

**Step 1 — accept, then close.** Rejecting a bad token by closing *before* `accept()` gives the
client a refused HTTP upgrade, which is indistinguishable from the server being down, so the
client retries a token that will never work. Accept first, then `close(4401)`, and the client
can read the code and give up.

**Step 2 — `async_to_sync`.** The channel layer is async and `argument_submit` is not. This is
the seam between the two worlds, and it is why `broadcast` lives in its own function rather
than inside the consumer.

**Step 3 — `transaction.on_commit`.** Broadcast the debate *after* the transaction commits.
Announce inside it and a fast client can fetch state that has not been written yet, or that a
rollback is about to erase.

**Step 5 — nothing writes `_debate` except a socket event.** Actions `await` the API only to
learn whether it failed; the new state arrives as a broadcast like everybody else's. One
writer means the two paths cannot drift.

**Step 7 — two banners that mean different things.** `Reconnecting…` is about the transport and
everybody sees it at once. The error banner is about one request and only its caller sees it.
Same screen, opposite audiences — this is the phase's rule, drawn. The composer goes dead in
the same breath, because a submit with no socket has nowhere to hear the answer.

**Step 8 — why the list only moves when it grows.** The provider now notifies on every
broadcast, and a `didUpdateWidget` that scrolls on all of them yanks the history back down
while somebody is reading through it. Compare the argument count with the one you were handed,
and follow only when it went up. Two more things bite: the new row does not exist until the
frame after the rebuild, so the scroll is booked with
`WidgetsBinding.instance.addPostFrameCallback`; and a controller with no `ListView` attached
has no `position` to read, so `hasClients` is checked before touching it. Both are lessons the
error message teaches the hard way if you skip them.

## Demo

Four browser windows: moderator, Team A, Team B, audience.

1. Moderator starts → all four update at once, nobody touches anything
2. Team A argues → appears everywhere instantly, and every window scrolls to it
3. Team B argues out of turn → **only Team B** sees the error; the other three see nothing
4. Now kill the Django server. All four show `Reconnecting…`
5. Start it again. They reconnect on their own and resync

Step 4 is the one to linger on. Killing a server in front of a room and having the app heal
itself is the most convincing thirty seconds in the whole workshop.

## A bug that is already fixed for you

`CHANNEL_LAYERS` uses `channels_redis.pubsub.RedisPubSubChannelLayer`, not the `core` layer
most tutorials show. The core layer's blocking read races its own socket timeout against
recent redis-py, and idle sockets drop about every five seconds — which looks exactly like a
bug in your reconnect code. If a student pastes `core.RedisChannelLayer` in from a blog post,
this is what they will see.

## What this phase is worth in the syllabus

Concurrency and the async/sync boundary, two processes over one broker (Module IV, lab 9);
Futures, `async`/`await`, `Stream` and `StreamSubscription`, exception handling, debugging a
live app (Module V); real-time push as the alternative to polling — the Firestore
`onSnapshot` idea, done with Channels (Module VI).

## Reference

```bash
git diff phase-2-start..phase-2-complete --stat
git diff phase-2-start..phase-2-complete
```
