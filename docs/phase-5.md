# Phase 5 — Polish and package

**Tags:** `phase-5-start` → `phase-5-complete`

The product is finished at the end of phase 4. This phase is about everything around it: a
package of your own, a brand, a room on screen, a layout that suits a projector as well as a
phone, and an app the room can install.

Each step is small and visible. None of it is busywork — every piece fixes something the app
was actually missing.

## Your dial tone

```bash
cd packages/refbot_core && dart test    # 6 tests, all red
cd app && flutter test                  # 37 tests, 2 of them red
```

The package tests are steps 1 and 2. The two red widget tests are step 6.

## Steps

| # | Where | What |
|---|---|---|
| 1 | `packages/refbot_core/lib/src/join_code.dart` | `normalizeJoinCode`, `isValidJoinCode` |
| 2 | `packages/refbot_core/lib/src/wire.dart` | `fromWire` — one lookup for every wire enum |
| 3 | `app/lib/models/enums.dart` | `with Wire` on all five enums; `fromWire` in `SessionProvider` |
| 4 | `app/lib/screens/join_screen.dart` | Validate the code before sending it |
| 5 | `app/pubspec.yaml`, `theme.dart`, `home_screen.dart` | Declare the assets and the font, use them |
| 6 | `app/lib/widgets/participant_grid.dart` | Who is in the room, as a grid |
| 7 | `app/lib/screens/debate_screen.dart` | Two columns on a wide screen |
| 8 | `app/web/manifest.json`, `index.html` | Make it installable |

## 1–2 · Your own package

`packages/refbot_core` is a **pure Dart package** — no Flutter in it, so its tests run in
milliseconds with plain `dart test`. The app reaches it by path:

```yaml
refbot_core:
  path: ../packages/refbot_core
```

No publishing, no version numbers, no pub.dev account. That is the normal way to share code
between an app and its tools, and it is how a package starts before it is ever published.

Run its tests from inside the package:

```bash
cd packages/refbot_core && dart test
```

Six tests, all red. That is steps 1 and 2.

## 3 · A mixin that earns its place

`Wire` is one line — `String get wire` — but it is what makes `fromWire` possible:

```dart
T? fromWire<T extends Wire>(List<T> values, String? wire)
```

Without the mixin there is no bound to write, so every enum needs its own copy of the lookup.
With it, one function serves `Side`, `Role`, `DebateStatus`, `AnalysisStatus` and
`ClaimAssessment`. Dart enums can mix in, which surprises people.

Go and delete the `firstWhere` in `SessionProvider` once it works. That is the payoff.

## 4 · Validation on the client too

The backend already rejects a bad join code with a clear 404. Validating in the app as well is
not duplication — it is the difference between a red field as you type and a round trip that
tells you off afterwards. Same rule, two places, and now it lives in one file that both could
share.

The `errorText` only appears once there is something to complain about, so an empty field is
not an error yet. That needs the field to rebuild as it is typed in: `onChanged: (_) =>
setState(() {})`, ephemeral state again, in the smallest form it takes anywhere in the app.

## 5 · Assets and fonts

`assets/fonts/` and `assets/images/` already hold the files. Only the `pubspec.yaml` wiring is
missing, and that is the part people get wrong: the indentation under `flutter:`, the `family`
name matching `fontFamily` in the theme, the trailing slash on a directory asset.

Space Grotesk is under the SIL Open Font License; the licence sits beside it in
`assets/fonts/OFL.txt`. Shipping a font means shipping its licence.

## 6 · A grid, and why it is not a column

The starter draws the room as a `Column` of chips, which is what everybody writes first. Turn
it into a `GridView.builder` laid out by
`SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 180, mainAxisExtent: 56)`.

Two things are worth saying while you do it. `maxCrossAxisExtent` means you never pick a column
count — the grid fits as many 180-wide chips as the space allows, so the same code is two
columns on a phone and six on the projector. And the fixed `mainAxisExtent` is what keeps the
grid off the intrinsic-size path: without it, the grid has to ask every chip how tall it wants
to be before laying any of them out, and that question gets more expensive with every person
who joins.

It scrolls inside a panel that already scrolls, so it takes `shrinkWrap: true` and
`NeverScrollableScrollPhysics` — two scrollables fighting over one gesture is the next bug you
would have hit.

## 7 · One layout, two shapes

```dart
final isWide = MediaQuery.sizeOf(context).width >= 900;
```

Above 900 logical pixels the history moves left and the `ParticipantGrid` from step 6 appears
on the right. Below it, the history is the whole screen. One breakpoint, no separate phone
build, no platform check — the same binary is projecting on the wall and running on the phones
in front of everyone.

## 8 · Installable

`flutter build web` already emits `flutter_service_worker.js` and a `manifest.json`. A Flutter
web app is a PWA by default — what phase 5 adds is making it *yours*: the real name, the
theme colour, a description.

```bash
flutter build web --release
ls build/web/flutter_service_worker.js build/web/manifest.json
```

Serve `build/web` over your LAN and open it on a phone: Chrome offers **Add to home screen**,
and it launches without browser chrome. That is the whole of "Progressive Web App" made
concrete in about ninety seconds.

## Demo

Project the app at full width, then drag the window narrow. The participant grid appears and
disappears at the breakpoint, and reflows its columns on the way. Then install it on a phone
from the LAN address and open it from the home screen.

## What this phase is worth in the syllabus

Developing a package, types of packages, using Dart packages (Module VI); mixins, generics and
advanced OOP, media query, advanced layout, lists and grids, styles, assets and fonts
(Modules V and VI); Progressive Web Apps (Module I); lab experiment 15.

## Reference

```bash
git diff phase-5-start..phase-5-complete --stat
```
