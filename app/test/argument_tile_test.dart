import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refbot/models/argument.dart';
import 'package:refbot/models/enums.dart';
import 'package:refbot/widgets/argument_tile.dart';

Argument _argument({
  Side side = Side.teamA,
  int roundNumber = 2,
  String body = 'Attention is the product, and the product is us.',
  String? authorName = 'Ada',
}) => Argument(
  id: 'a1',
  side: side,
  roundNumber: roundNumber,
  body: body,
  createdAt: DateTime.utc(2026, 3, 14),
  authorName: authorName,
);

Future<void> _pump(WidgetTester tester, Argument argument) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ArgumentTile(argument: argument)),
      ),
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
}
