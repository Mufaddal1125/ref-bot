import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:refbot/core/api_client.dart';
import 'package:refbot/models/debate.dart';
import 'package:refbot/models/enums.dart';
import 'package:refbot/models/vote_tally.dart';
import 'package:refbot/providers/debate_provider.dart';
import 'package:refbot/widgets/vote_panel.dart';

Debate _debate({
  DebateStatus status = DebateStatus.voting,
  VoteTally tally = const VoteTally(teamA: 3, teamB: 1, total: 4),
}) => Debate(
  id: 'd1',
  topic: 'Social media does more harm than good',
  joinCode: 'ABC234',
  status: status,
  currentSide: Side.teamA,
  currentRound: 2,
  tally: tally,
);

Future<void> _pump(WidgetTester tester, Debate debate, Role role) async {
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => DebateProvider(ApiClient()),
      child: MaterialApp(
        home: Scaffold(body: VotePanel(debate: debate, role: role)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('voting opens with a ballot, not a result', (tester) async {
    await _pump(tester, _debate(), Role.audience);

    expect(find.text('Who won the debate?'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Team A'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Team B'), findsOneWidget);
    expect(find.text('75%'), findsNothing);
  });

  testWidgets('a closed debate shows the tally instead', (tester) async {
    await _pump(tester, _debate(status: DebateStatus.closed), Role.audience);

    expect(find.text('Who won the debate'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('4 votes'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Team A'), findsNothing);
  });

  testWidgets('only the moderator can close the voting', (tester) async {
    await _pump(tester, _debate(), Role.moderator);
    expect(find.text('Close voting'), findsOneWidget);

    await _pump(tester, _debate(), Role.audience);
    expect(find.text('Close voting'), findsNothing);
  });

  testWidgets('there is nothing to close once it is closed', (tester) async {
    await _pump(tester, _debate(status: DebateStatus.closed), Role.moderator);

    expect(find.text('Close voting'), findsNothing);
  });
}
