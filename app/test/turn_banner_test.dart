import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refbot/models/debate.dart';
import 'package:refbot/models/enums.dart';
import 'package:refbot/widgets/turn_banner.dart';

Debate _debate({
  DebateStatus status = DebateStatus.active,
  Side currentSide = Side.teamA,
  int currentRound = 1,
}) => Debate(
  id: 'd1',
  topic: 'Social media does more harm than good',
  joinCode: 'ABC234',
  status: status,
  currentSide: currentSide,
  currentRound: currentRound,
);

Future<void> _pump(WidgetTester tester, Debate debate, Role role) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TurnBanner(debate: debate, role: role)),
      ),
    );

void main() {
  testWidgets('the lobby waits for the moderator', (tester) async {
    await _pump(tester, _debate(status: DebateStatus.lobby), Role.teamA);

    expect(find.text('Waiting for the moderator to start'), findsOneWidget);
  });

  testWidgets('the team whose turn it is is told so', (tester) async {
    await _pump(tester, _debate(currentRound: 2), Role.teamA);

    expect(find.text('Your turn — round 2'), findsOneWidget);
  });

  testWidgets('everybody else is told whose turn it is', (tester) async {
    await _pump(tester, _debate(currentSide: Side.teamB), Role.audience);

    expect(find.text('Team B to speak — round 1'), findsOneWidget);
  });

  testWidgets('the moderator never gets a turn of their own', (tester) async {
    await _pump(tester, _debate(), Role.moderator);

    expect(find.text('Team A to speak — round 1'), findsOneWidget);
  });

  testWidgets('voting and closed each say so', (tester) async {
    await _pump(tester, _debate(status: DebateStatus.voting), Role.audience);
    expect(find.text('The debate has ended'), findsOneWidget);

    await _pump(tester, _debate(status: DebateStatus.closed), Role.audience);
    expect(find.text('Results are final'), findsOneWidget);
  });
}
