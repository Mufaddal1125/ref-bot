import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refbot/models/analysis.dart';
import 'package:refbot/models/enums.dart';
import 'package:refbot/widgets/analysis_card.dart';

Future<void> _pump(WidgetTester tester, RefereeAnalysis analysis) =>
    tester.pumpWidget(
      MaterialApp(home: Scaffold(body: AnalysisCard(analysis: analysis))),
    );

void main() {
  testWidgets('an empty analysis says so', (tester) async {
    await _pump(tester, const RefereeAnalysis());

    expect(find.text('The referee found nothing to flag.'), findsOneWidget);
  });

  testWidgets('a fallacy is named and explained', (tester) async {
    await _pump(
      tester,
      const RefereeAnalysis(
        fallacies: [
          Fallacy(
            name: 'Appeal to common belief',
            explanation: '"Everyone knows" is not evidence.',
          ),
        ],
      ),
    );

    expect(find.text('Appeal to common belief'), findsOneWidget);
    expect(find.text('"Everyone knows" is not evidence.'), findsOneWidget);
  });

  testWidgets('missing context is listed under its own heading', (
    tester,
  ) async {
    await _pump(
      tester,
      const RefereeAnalysis(
        missingContext: [MissingContext(text: 'No definition of "harm".')],
      ),
    );

    expect(find.text('Missing context'), findsOneWidget);
    expect(find.text('No definition of "harm".'), findsOneWidget);
  });

  testWidgets('a claim carries its assessment and the referee note', (
    tester,
  ) async {
    await _pump(
      tester,
      const RefereeAnalysis(
        claims: [
          Claim(
            text: 'Teen anxiety has doubled',
            assessment: ClaimAssessment.unverifiable,
            note: 'No source given.',
          ),
        ],
      ),
    );

    expect(find.text('Unverifiable claim'), findsOneWidget);
    expect(
      find.text('“Teen anxiety has doubled” — No source given.'),
      findsOneWidget,
    );
  });

  testWidgets('all three categories appear together', (tester) async {
    await _pump(
      tester,
      const RefereeAnalysis(
        claims: [
          Claim(
            text: 'A',
            assessment: ClaimAssessment.supported,
            note: 'Cited.',
          ),
        ],
        missingContext: [MissingContext(text: 'B')],
        fallacies: [Fallacy(name: 'Straw man', explanation: 'C')],
      ),
    );

    expect(find.text('Straw man'), findsOneWidget);
    expect(find.text('Missing context'), findsOneWidget);
    expect(find.text('Supported claim'), findsOneWidget);
  });
}
