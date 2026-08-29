import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refbot/models/analysis.dart';
import 'package:refbot/models/argument.dart';
import 'package:refbot/models/enums.dart';
import 'package:refbot/widgets/argument_tile.dart';

const _found = RefereeAnalysis(
  claims: [
    Claim(
      text: 'Teen anxiety has doubled',
      assessment: ClaimAssessment.unverifiable,
      note: 'No source given.',
    ),
  ],
  missingContext: [MissingContext(text: 'No definition of "harm".')],
  fallacies: [
    Fallacy(
      name: 'Appeal to common belief',
      explanation: '"Everyone knows" is not evidence.',
    ),
  ],
);

Argument _argument({
  Side side = Side.teamA,
  int roundNumber = 2,
  String body = 'Attention is the product, and the product is us.',
  String? authorName = 'Ada',
  Analysis? analysis,
}) => Argument(
  id: 'a1',
  side: side,
  roundNumber: roundNumber,
  body: body,
  createdAt: DateTime.utc(2026, 3, 14),
  authorName: authorName,
  analysis: analysis,
);

Future<void> _pump(WidgetTester tester, Argument argument) =>
    tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ArgumentTile(argument: argument))),
    );

void main() {
  testWidgets('a tile names the side, the round and the author', (
    tester,
  ) async {
    await _pump(tester, _argument());

    expect(find.text('Team A — Round 2'), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);
    expect(
      find.text('Attention is the product, and the product is us.'),
      findsOneWidget,
    );
  });

  testWidgets('team B is labelled as team B', (tester) async {
    await _pump(tester, _argument(side: Side.teamB, roundNumber: 3));

    expect(find.text('Team B — Round 3'), findsOneWidget);
  });

  testWidgets('an argument with no author shows none', (tester) async {
    await _pump(tester, _argument(authorName: null));

    expect(find.text('Ada'), findsNothing);
    expect(find.text('Team A — Round 2'), findsOneWidget);
  });

  testWidgets('an argument with no analysis has no referee row', (
    tester,
  ) async {
    await _pump(tester, _argument());

    expect(find.text('Referee is thinking…'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('a pending analysis says the referee is thinking', (
    tester,
  ) async {
    await _pump(
      tester,
      _argument(analysis: const Analysis(status: AnalysisStatus.pending)),
    );

    expect(find.text('Referee is thinking…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('a failed analysis reports why', (tester) async {
    await _pump(
      tester,
      _argument(
        analysis: const Analysis(
          status: AnalysisStatus.failed,
          error: 'REFEREE_API_KEY is not set in .env',
        ),
      ),
    );

    expect(
      find.text('Referee unavailable: REFEREE_API_KEY is not set in .env'),
      findsOneWidget,
    );
  });

  testWidgets('a finished analysis counts what it found', (tester) async {
    await _pump(
      tester,
      _argument(
        analysis: const Analysis(
          status: AnalysisStatus.complete,
          result: _found,
        ),
      ),
    );

    expect(find.text('1 🚨   1 ⚠   1 ✓'), findsOneWidget);
    expect(find.text('Appeal to common belief'), findsNothing);
  });

  testWidgets('a finished analysis that found nothing says so', (tester) async {
    await _pump(
      tester,
      _argument(
        analysis: const Analysis(
          status: AnalysisStatus.complete,
          result: RefereeAnalysis(),
        ),
      ),
    );

    expect(find.text('Referee found nothing to flag'), findsOneWidget);
  });

  testWidgets('tapping the tile unfolds the analysis, and folds it back', (
    tester,
  ) async {
    await _pump(
      tester,
      _argument(
        analysis: const Analysis(
          status: AnalysisStatus.complete,
          result: _found,
        ),
      ),
    );

    await tester.tap(find.text('1 🚨   1 ⚠   1 ✓'));
    await tester.pumpAndSettle();

    expect(find.text('Appeal to common belief'), findsOneWidget);
    expect(find.text('Missing context'), findsOneWidget);
    expect(find.text('Unverifiable claim'), findsOneWidget);

    await tester.tap(find.text('1 🚨   1 ⚠   1 ✓'));
    await tester.pumpAndSettle();

    expect(find.text('Appeal to common belief'), findsNothing);
  });
}
