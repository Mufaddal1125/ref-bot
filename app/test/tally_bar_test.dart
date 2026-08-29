import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refbot/models/vote_tally.dart';
import 'package:refbot/widgets/tally_bar.dart';

final _bar = find.byWidgetPredicate(
  (widget) =>
      widget is CustomPaint &&
      widget.painter != null &&
      widget.size.height == 28,
);

Future<void> _pump(WidgetTester tester, VoteTally tally) async {
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: TallyBar(tally: tally))),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('each side gets its share as a whole percentage', (tester) async {
    await _pump(tester, const VoteTally(teamA: 3, teamB: 1, total: 4));

    expect(find.text('Team A'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    expect(find.text('Team B'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('an empty ballot opens even rather than blank', (tester) async {
    await _pump(tester, const VoteTally());

    expect(find.text('50%'), findsNWidgets(2));
    expect(find.text('0 votes'), findsOneWidget);
  });

  testWidgets('one vote is a vote, not votes', (tester) async {
    await _pump(tester, const VoteTally(teamA: 1, total: 1));

    expect(find.text('1 vote'), findsOneWidget);
  });

  testWidgets('the bar clips itself round and fills both shares', (
    tester,
  ) async {
    await _pump(tester, const VoteTally(teamA: 3, teamB: 1, total: 4));

    expect(
      tester.renderObject(_bar),
      paints
        ..clipRRect()
        ..rect()
        ..rect(),
    );
  });

  testWidgets('the share is animated, so the bar slides instead of jumping', (
    tester,
  ) async {
    await _pump(tester, const VoteTally(teamA: 3, teamB: 1, total: 4));

    expect(
      find.ancestor(
        of: _bar,
        matching: find.byType(TweenAnimationBuilder<double>),
      ),
      findsOneWidget,
    );
  });
}
