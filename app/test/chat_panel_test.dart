import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:refbot/core/api_client.dart';
import 'package:refbot/models/chat_message.dart';
import 'package:refbot/models/enums.dart';
import 'package:refbot/providers/debate_provider.dart';
import 'package:refbot/widgets/chat_panel.dart';

/// The real provider with its socket swapped out for a list. Everything the
/// panel reads is a getter, so overriding is enough — nothing has to connect.
class _FakeDebates extends DebateProvider {
  _FakeDebates({
    List<ChatMessage> messages = const [],
    this.connected = true,
    this.failure,
  }) : messages = List.of(messages),
       super(ApiClient());

  final List<ChatMessage> messages;
  final bool connected;
  final String? failure;

  final sent = <String>[];
  final removed = <String>[];

  @override
  List<ChatMessage> get chatMessages => messages;

  @override
  bool get isConnected => connected;

  @override
  String? get chatError => failure;

  @override
  void sendChat(String body) => sent.add(body.trim());

  @override
  Future<void> deleteChatMessage(String messageId) async =>
      removed.add(messageId);
}

ChatMessage _message({
  String id = 'm1',
  String authorName = 'Ada',
  Role authorRole = Role.audience,
  String body = 'hello there',
}) => ChatMessage(
  id: id,
  authorName: authorName,
  authorRole: authorRole,
  body: body,
  createdAt: DateTime(2026, 1, 1, 14, 32),
);

Future<void> _pump(
  WidgetTester tester,
  _FakeDebates debates, {
  Role role = Role.audience,
}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<DebateProvider>.value(
      value: debates,
      child: MaterialApp(home: Scaffold(body: ChatPanel(role: role))),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an empty chat invites the first message', (tester) async {
    await _pump(tester, _FakeDebates());

    expect(find.text('No messages yet. Say hello.'), findsOneWidget);
  });

  testWidgets('every message in the room is listed', (tester) async {
    await _pump(
      tester,
      _FakeDebates(
        messages: [
          _message(id: 'm1', authorName: 'Ada', body: 'hello there'),
          _message(id: 'm2', authorName: 'Grace', body: 'go team A'),
        ],
      ),
    );

    expect(find.textContaining('Ada', findRichText: true), findsOneWidget);
    expect(
      find.textContaining('go team A', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('No messages yet. Say hello.'), findsNothing);
  });

  testWidgets('sending hands the text over and clears the box', (tester) async {
    final debates = _FakeDebates();
    await _pump(tester, debates);

    await tester.enterText(find.byType(TextField), '  hello  ');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    expect(debates.sent, ['hello']);
    expect(tester.widget<TextField>(find.byType(TextField)).controller?.text, '');
  });

  testWidgets('an empty message is not worth sending', (tester) async {
    final debates = _FakeDebates();
    await _pump(tester, debates);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    expect(debates.sent, isEmpty);
  });

  testWidgets('a dropped socket takes the composer with it', (tester) async {
    await _pump(tester, _FakeDebates(connected: false));

    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    expect(find.text('Reconnecting…'), findsOneWidget);
  });

  testWidgets('a refused send is reported without touching the debate', (
    tester,
  ) async {
    await _pump(tester, _FakeDebates(failure: 'Slow down a moment.'));

    expect(find.text('Slow down a moment.'), findsOneWidget);
  });

  testWidgets('only the moderator can remove a message', (tester) async {
    await _pump(tester, _FakeDebates(messages: [_message()]));
    expect(find.byIcon(Icons.backspace_outlined), findsNothing);

    final debates = _FakeDebates(messages: [_message(id: 'm7')]);
    await _pump(tester, debates, role: Role.moderator);
    await tester.tap(find.byIcon(Icons.backspace_outlined));

    expect(debates.removed, ['m7']);
  });
}
