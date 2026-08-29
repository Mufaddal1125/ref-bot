---
name: flutter-app
description: Flutter/Dart conventions for app/ — read before writing or editing a widget, screen, provider, model, API call, socket handler, or route.
---

# RefBot Flutter conventions

This code gets typed live in front of a room. Write for someone seeing it once, on a projector: short widgets, obvious names, no abstraction a student has to take on faith.

## Where logic goes

| Folder | Holds |
|---|---|
| `screens/`, `widgets/` | Layout, `context.watch`, show/hide, animation. |
| `providers/` | State and every decision. `ChangeNotifier`. |
| `core/` | `ApiClient`, `DebateSocket`, router, env. All I/O. |
| `models/` | Immutable data plus `json_serializable`. |

Widgets stay dumb. A widget that computes something is a provider method waiting to be extracted. Widgets call provider methods, never `ApiClient` directly.

Providers are the whole state layer — they call `ApiClient` and hold the result. This app deliberately runs without repositories, use-cases, `freezed`, or a service locator; `provider` + `ChangeNotifier` + `json_serializable` is the complete list of moving parts, and adding a layer costs more to explain than it saves.

## Widgets

- `const` on every widget that takes no runtime value. `flutter_lints` flags the misses.
- Split at ~60 lines of `build`, into a private `_SomethingCard` widget in the same file. Extract to `widgets/` once a second screen uses it.
- Write widget classes, not `Widget _buildFoo()` methods — a class rebuilds independently, a method does not.
- Watch the narrowest thing: `context.select((DebateProvider p) => p.currentSide)` over `context.watch<DebateProvider>()` when only one field matters.
- `context.read` inside callbacks, `context.watch` inside `build`.
- Long lists use `ListView.builder`.

## Providers

```dart
class DebateProvider extends ChangeNotifier {
  Debate? _debate;
  Debate? get debate => _debate;

  Future<void> submitArgument(String body) async {
    await _api.submitArgument(body);
  }
}
```

Expose state through getters over private fields, so a widget cannot mutate it. Call `notifyListeners()` once, at the end of a change. Keep a single `bool isLoading` and `String? error` per provider rather than an enum of states.

## Models

`json_serializable` only, one class per file, all fields `final`:

```dart
@JsonSerializable()
class Argument {
  final String id;
  final Side side;
  final int roundNumber;

  const Argument({required this.id, required this.side, required this.roundNumber});

  factory Argument.fromJson(Map<String, dynamic> json) => _$ArgumentFromJson(json);
}
```

Set `fieldRename: FieldRename.snake` in `build.yaml` so Dart stays camelCase against the Django snake_case payload. Generated `.g.dart` files are committed.

`ServerEvent` needs a hand-written factory switching on `type` — `json_serializable` has no union support.

## Dart style

Follow Effective Dart. The rules that come up most here:

- Interpolate rather than concatenate; drop the braces when the expression is a bare identifier: `'Round $round'`.
- `final` for locals that never reassign; `var` when they do. Annotate only where inference misses.
- Arrow bodies for one-expression functions.
- `.isEmpty` / `.isNotEmpty`, never `.length == 0`.
- `async`/`await` over `.then()`, and no `async` on a function that never awaits.
- Nullable fields default to `null` already, so leave them uninitialised.
- Collection `if` and spreads instead of building lists imperatively:
  ```dart
  children: [
    const TurnBanner(),
    if (isMyTurn) const ArgumentComposer(),
    ...arguments.map(ArgumentTile.new),
  ],
  ```

## Comments and doc comments

One line, or none.

- `///` on a public class or method whose name leaves something unsaid. Start with a single sentence; a fragment is fine.
- The signature already states the parameters and the return, so leave them out of the comment.
- A `//` earns its place only for something surprising — a reconnect backoff, a platform quirk, a deliberate ordering. Not for narrating the next line.

```dart
/// Streams debate events, reconnecting with backoff and resyncing on reconnect.
class DebateSocket {
```

## Errors

`ApiClient` throws `ApiException(status, code, message)`; providers catch it and set `error`. Widgets read `error` and render it. Let anything unexpected crash in dev — a swallowed exception is a bug nobody can see from the back row.

## Starter stubs

Phase starter commits ship every file present, compiling, and analysing clean, with bodies replaced by a TODO. A method that returns data throws:

```dart
Future<void> submitArgument(String body) async {
  throw UnimplementedError(); // TODO(step 7): post, then append to _arguments
}
```

A `build` returns a `Placeholder()` where the missing layout goes, so `flutter run` still works at the starter tag and the crossed boxes on screen are the to-do list:

```dart
@override
Widget build(BuildContext context) {
  // TODO(step 8): a Card holding the side, the round and the body.
  return const Card(child: SizedBox(height: 72, child: Placeholder()));
}
```

Keep the signature, the doc comment, and the imports real — but drop an import the stub no longer uses and name it in the TODO instead, so `flutter analyze` stays clean at every tag, starters included. Where a stub leaves a field or a callback dangling, either keep the button that calls it or add an `// ignore:` with a one-line reason.

## Tests

`app/test/` holds one file per widget worth pinning down, named after it. They are written *for* the student: a phase's tests ship red in its starter and go green as its steps land, so `flutter test` reports progress on the client the way `pytest` does on the server.

Pump the widget with plain constructor arguments where it takes them, and wrap it in a `ChangeNotifierProvider` only when it reads one:

```dart
await tester.pumpWidget(
  MaterialApp(home: Scaffold(body: TurnBanner(debate: debate, role: Role.teamA))),
);
```

Assert on what the room can see — the text, how many tiles, which button is disabled — never on private state.

## Config

Base URL comes from `--dart-define`, read once in `core/env.dart`. No other per-platform branching exists — the app is one codebase across web, desktop, and mobile.
