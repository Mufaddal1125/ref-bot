---
name: django-backend
description: Django/DRF/Channels conventions for backend/ — read before writing or editing a model, serializer, view, service, consumer, RQ job, migration, settings module, or test.
---

# RefBot backend conventions

This code gets typed live in front of a room. Write for someone seeing it once, on a projector: short functions, obvious names, no indirection you would have to stop and explain.

## Where logic goes

| File | Holds |
|---|---|
| `models.py` | Fields, `Meta`, `__str__`. |
| `services.py` | Every write and every state change. |
| `selectors.py` | Reads that take more than one line of ORM. |
| `views.py` | Parse input → call a service → return a serializer. |
| `consumers.py` | Socket lifecycle and dispatch. |
| `jobs.py` | RQ entrypoints: load, call, save, broadcast. |
| `referee/clients/` | One file per AI provider. The only place the `openai` SDK is imported. |

A view and a consumer that do the same thing call the **same service function**. One copy.

Keep views thin. A view body past ~10 lines has a service hiding in it.

Business logic lives in `services.py` — not in `save()`, signals, or custom managers, which move it somewhere the reader has to go hunt for.

## Naming

- Services and selectors: `<entity>_<action>` — `argument_submit`, `debate_join`, `vote_tally`.
- Serializers: `<Entity><Direction>Serializer` — `ArgumentInSerializer`, `DebateOutSerializer`. Input and output stay separate classes.
- API classes: `<Entity><Action>Api` — `ArgumentCreateApi`.
- WebSocket event types: `<noun>.<verb>` — `argument.created`, `analysis.updated`.

## Services

```python
@transaction.atomic
def argument_submit(*, debate: Debate, participant: Participant, body: str) -> Argument:
    """Record an argument and hand the turn to the other side."""
```

- Keyword-only arguments. Annotate the parameters and the return.
- Raise `DomainError` subclasses from `apps/common/errors.py`. The DRF exception handler maps them to status codes, so services build no `Response`.
- Call `full_clean()` before `save()` on models that validate.
- Side effects that must outlive the transaction go in `transaction.on_commit`: broadcasts, job enqueues.

## Views

Use `APIView` with a single method. A student reads `post()` top to bottom; nobody reads a router.

```python
class ArgumentCreateApi(APIView):
    permission_classes = [IsCurrentTurnTeam]

    def post(self, request, debate_id):
        payload = ArgumentInSerializer(data=request.data)
        payload.is_valid(raise_exception=True)
        argument = argument_submit(
            debate=debate_get(debate_id), participant=request.user, **payload.validated_data
        )
        return Response(ArgumentOutSerializer(argument).data, status=201)
```

`request.user` is a `Participant`, not a Django `User` — `ParticipantTokenAuthentication` puts it there.

## Consumers

**The socket only sends.** Every change arrives as a REST request; the consumer authenticates,
joins the debate's group, and fans broadcasts out. It calls no service and makes no
authorisation decision of its own, so there is nothing to keep in step with the permission
classes.

That split also settles who sees a failure: a rejected write is an HTTP error for its one
caller, and a successful one is a broadcast for everybody.

Server events are `{"type": ..., "payload": {...}}`. Reach the ORM through
`database_sync_to_async`. Services broadcast through `apps/common/broadcast.py` inside
`transaction.on_commit`.

## The AI provider seam

`apps/referee/clients/` is the only place a provider SDK is imported. Clients implement the
`RefereeClient` protocol in `clients/base.py`: plain arguments in, a `RefereeResult` of
Pydantic domain objects out.

Everything upstream — `jobs.py`, the `Analysis` model, the serializer, Flutter — sees the
same shape whoever answered. Another OpenAI-compatible provider needs only a different
`REFEREE_BASE_URL`; one with its own protocol needs a new file here.

Gemini is reached through the OpenAI SDK against Google's compatibility endpoint:
`client.chat.completions.parse(..., response_format=RefereeAnalysis)`. `.parse()` builds the
strict JSON schema from the Pydantic model, so write no schema by hand. Treat
`message.parsed is None` as a failed analysis rather than saving an empty result.

## Comments and docstrings

One line, or none.

- A docstring states the side effect or the *why*. When the function name already says it, skip the docstring.
- Type hints carry the arguments and the return, so leave out `Args:` / `Returns:` blocks.
- An inline `#` earns its place only for something surprising — a row lock, a race, a third-party quirk. Not for narrating the next line.

```python
# Two teammates can hit submit at once; lock the turn counter.
debate = Debate.objects.select_for_update().get(pk=debate.pk)
```

## Errors

Every failure raises a `DomainError` subclass carrying a stable `code`:

```python
raise NotYourTurn(code="not_your_turn")   # -> 409 {"code": ..., "message": ...}
```

One response shape for every error, so the Flutter `ApiException` parses one thing.

## Starter stubs

Phase starter commits ship every file present and importable, with bodies replaced by:

```python
def argument_submit(*, debate, participant, body):
    """Record an argument and hand the turn to the other side."""
    raise NotImplementedError  # TODO(step 3): validate turn, create, advance
```

Keep the signature, the docstring, and the imports real. Only the body is missing, so the app still starts at the starter tag.

## Settings

`config/settings/base.py` holds everything; `dev.py` and `workshop_offline.py` import it and override. Values that change per machine come from the environment, with a working default for local dev.

Redis is split by purpose: db 0 channel layer, db 1 cache, db 2 RQ.

## Tests

pytest, one behaviour per test, named `test_<what>_<when>`. Cover the turn machine, its rejections, and the vote uniqueness rule. Skip tests that only restate a field list.
