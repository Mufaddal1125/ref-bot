import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refbot/models/chat_message.dart';
import 'package:refbot/models/enums.dart';
import 'package:refbot/widgets/chat_message_tile.dart';

ChatMessage _message({
  String id = 'm1',
  String authorName = 'Ada',
  Role authorRole = Role.audience,
  String body = 'good point',
  bool isDeleted = false,
}) => ChatMessage(
  id: id,
  authorName: authorName,
  authorRole: authorRole,
  body: isDeleted ? '' : body,
  createdAt: DateTime(2026, 1, 1, 14, 32),
  isDeleted: isDeleted,
);

Future<void> _pump(
  WidgetTester tester,
  ChatMessage message, {
  VoidCallback? onDelete,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: ChatMessageTile(message: message, onDelete: onDelete),
    ),
  ),
);

void main() {
  testWidgets('a message shows the time, the name and the words', (
    tester,
  ) async {
    await _pump(tester, _message());

    expect(find.textContaining('14:32', findRichText: true), findsOneWidget);
    expect(find.textContaining('Ada', findRichText: true), findsOneWidget);
    expect(
      find.textContaining('good point', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('the moderator and the teams are badged', (tester) async {
    await _pump(tester, _message(authorRole: Role.moderator));
    expect(find.text('MOD'), findsOneWidget);

    await _pump(tester, _message(authorRole: Role.teamA));
    expect(find.text('A'), findsOneWidget);

    await _pump(tester, _message(authorRole: Role.teamB));
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('the audience is everybody, so it wears no badge', (
    tester,
  ) async {
    await _pump(tester, _message(authorRole: Role.audience));

    expect(find.text('MOD'), findsNothing);
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsNothing);
  });

  testWidgets('a removed message keeps its time but loses name and words', (
    tester,
  ) async {
    await _pump(tester, _message(isDeleted: true));

    expect(find.textContaining('14:32', findRichText: true), findsOneWidget);
    expect(
      find.textContaining(
        'message removed by the moderator',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Ada', findRichText: true), findsNothing);
  });

  testWidgets('the remove button appears only when there is one to call', (
    tester,
  ) async {
    await _pump(tester, _message());
    expect(find.byIcon(Icons.backspace_outlined), findsNothing);

    var removed = 0;
    await _pump(tester, _message(), onDelete: () => removed++);
    await tester.tap(find.byIcon(Icons.backspace_outlined));

    expect(removed, 1);
  });
}
