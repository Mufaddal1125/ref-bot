import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refbot/models/enums.dart';
import 'package:refbot/models/participant.dart';
import 'package:refbot/widgets/participant_grid.dart';

const _room = [
  Participant(id: 'p1', displayName: 'Ada', role: Role.moderator),
  Participant(id: 'p2', displayName: 'Grace', role: Role.teamA),
  Participant(id: 'p3', displayName: 'Alan', role: Role.audience),
];

Future<void> _pump(WidgetTester tester, List<Participant> participants) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ParticipantGrid(participants: participants)),
      ),
    );

void main() {
  testWidgets('everybody in the room is named, with their role', (
    tester,
  ) async {
    await _pump(tester, _room);

    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('Moderator'), findsOneWidget);
    expect(find.text('Grace'), findsOneWidget);
    expect(find.text('Team A'), findsOneWidget);
    expect(find.text('Alan'), findsOneWidget);
    expect(find.text('Audience'), findsOneWidget);
  });

  testWidgets('an empty room still lays out', (tester) async {
    await _pump(tester, const []);

    expect(find.byType(GridView), findsOneWidget);
    expect(find.text('Ada'), findsNothing);
  });

  testWidgets('the chips are laid out in a grid with a fixed row height', (
    tester,
  ) async {
    await _pump(tester, _room);

    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithMaxCrossAxisExtent;

    expect(delegate.maxCrossAxisExtent, 180);
    // A fixed extent is what keeps the grid off the intrinsic-size path.
    expect(delegate.mainAxisExtent, 56);
  });
}
