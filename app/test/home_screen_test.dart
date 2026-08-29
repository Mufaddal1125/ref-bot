import 'package:flutter_test/flutter_test.dart';
import 'package:refbot/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('with no stored session the app opens on the home screen', (
    tester,
  ) async {
    await tester.pumpWidget(const RefBotApp());
    await tester.pumpAndSettle();

    expect(find.text('RefBot'), findsOneWidget);
    expect(
      find.text('Humans debate. AI referees. The audience decides.'),
      findsOneWidget,
    );
    expect(find.text('Start a debate'), findsOneWidget);
    expect(find.text('Join with a code'), findsOneWidget);
  });

  testWidgets('Start a debate goes to the create screen', (tester) async {
    await tester.pumpWidget(const RefBotApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start a debate'));
    await tester.pumpAndSettle();

    expect(find.text('Create as moderator'), findsOneWidget);
  });

  testWidgets('Join with a code goes to the join screen', (tester) async {
    await tester.pumpWidget(const RefBotApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Join with a code'));
    await tester.pumpAndSettle();

    expect(find.text('Join a debate'), findsOneWidget);
  });
}
