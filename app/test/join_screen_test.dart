import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:refbot/core/api_client.dart';
import 'package:refbot/models/enums.dart';
import 'package:refbot/providers/session_provider.dart';
import 'package:refbot/screens/join_screen.dart';

Widget _host() => ChangeNotifierProvider(
  create: (_) => SessionProvider(ApiClient()),
  child: const MaterialApp(home: JoinScreen()),
);

void main() {
  testWidgets('the form asks for a code, a name and a role', (tester) async {
    await tester.pumpWidget(_host());

    expect(find.text('Join a debate'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.byType(SegmentedButton<Role>), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Join'), findsOneWidget);
  });

  testWidgets('the role picker offers the three joinable roles', (
    tester,
  ) async {
    await tester.pumpWidget(_host());

    expect(find.text('Team A'), findsOneWidget);
    expect(find.text('Team B'), findsOneWidget);
    expect(find.text('Audience'), findsOneWidget);
    expect(find.text('Moderator'), findsNothing);
  });

  testWidgets('picking a role is ephemeral state, kept with setState', (
    tester,
  ) async {
    await tester.pumpWidget(_host());

    SegmentedButton<Role> picker() =>
        tester.widget(find.byType(SegmentedButton<Role>));

    expect(picker().selected, {Role.teamA});

    await tester.tap(find.text('Audience'));
    await tester.pumpAndSettle();

    expect(picker().selected, {Role.audience});
  });
}
