import 'package:fluffychat/config/setting_keys.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';

import 'package:fluffychat/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

import 'extensions/default_flows.dart';
import 'extensions/wait_for.dart';
import 'users.dart';

Future<void> waitFor(tester, condition, expectation, duration) async {
  const defaultDelay = 100;
  final iterations = duration / defaultDelay;
  var found = false;
  var lastException;
  for (var i = 0; i < iterations; i++) {
    await Future.delayed(const Duration(milliseconds: defaultDelay));
    final pumpedFrames = await tester.pumpAndSettle();
    print('pumped $pumpedFrames after $i iterations');
    try {
      expect(condition, expectation);
      found = true;
      break;
    } catch (exception) {
      print('not found $i');
      lastException = exception;
    }
  }
  if (!found) throw lastException;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.testTextInput.register(); // makes enterText work

  group(
    'Integration Test',
    () {
      setUpAll(
        () async {
          // this random dialog popping up is super hard to cover in tests
          SharedPreferences.setMockInitialValues({
            SettingKeys.showNoGoogle: false,
          });
          try {
            Hive.deleteFromDisk();
            Hive.initFlutter();
          } catch (_) {}
        },
      );

      testWidgets(
        'Start app, login and logout',
        (WidgetTester tester) async {
          app.main();
          await tester.ensureAppStartedHomescreen();
          await tester.ensureLoggedOut();
        },
      );

      testWidgets(
        'Login again',
        (WidgetTester tester) async {
          app.main();
          await tester.ensureAppStartedHomescreen();
        },
      );

      testWidgets('Start a new chat with the integration user 02',
          (WidgetTester tester) async {
        app.main();
        await tester.ensureAppStartedHomescreen();
        await pumpX(tester);
        await tester.tap(find.text('New chat'));
        await pumpX(tester);
        final inviteLink = find.byType(TextField);
        await waitForFairkom(tester, inviteLink, findsOneWidget, 2000);
        await tester.enterText(inviteLink,
            "https://matrix.to/#/@${Users.user2.name}:devmh.fairmatrix.net");
        await tester.pump(const Duration(seconds: 2));
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await pumpX(tester);
        await tester.tap(find.widgetWithText(Row, 'New chat'));
        await pumpX(tester);
      });

      testWidgets(
        'Start chat and send message',
        (WidgetTester tester) async {
          app.main();
          await tester.ensureAppStartedHomescreen();
          await tester.enterText(find.byType(TextField), Users.user2.name);
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await pumpX(tester);

          // await tester.scrollUntilVisible(
          //   find.text(Users.user2.name).first,
          //   500,
          //   scrollable: find.descendant(
          //     of: find.byType(ChatListViewBody),
          //     matching: find.byType(Scrollable),
          //   ),
          // );
          // for (int i = 0; i < 5; i++) {
          //   // because pumpAndSettle doesn't work
          //   await tester.pump(const Duration(seconds: 1));
          // }
          await tester.tap(find.widgetWithText(ListTile, Users.user2.name).first);
          await pumpX(tester);
          await tester.enterText(find.byType(EditableText), "Test message");
          await pumpX(tester);
          await tester.tap(find.byTooltip('Read receipt on'));
          await pumpX(tester);
          await tester.tap(find.byTooltip('Send'));
          await pumpX(tester);
        },
      );

      testWidgets(
        'Logout, login with second test user and look for a chat with user1',
            (WidgetTester tester) async {
          app.main();
          await tester.ensureAppStartedHomescreen();
          await tester.ensureLoggedOut();
          await tester.ensureAppStartedHomescreen(loginUsername: Users.user2.name, loginPassword: Users.user2.password);

          await tester.enterText(find.byType(TextField), Users.user1.name);
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await pumpX(tester);
          await tester.tap(find.text(Users.user1.name).first);
          await pumpX(tester);
          expect(find.text("Test message"), findsAtLeastNWidgets(1));
          // todo click on open Lesebestätigung

          await pumpX(tester);

        },
      );

      testWidgets(
        'Delete chat with user integration1',
            (WidgetTester tester) async {
          app.main();
          await tester.ensureAppStartedHomescreen();
          await tester.ensureLoggedOut();
          await tester.ensureAppStartedHomescreen(loginUsername: Users.user2.name, loginPassword: Users.user2.password);

          await tester.enterText(find.byType(TextField), Users.user1.name);
          // todo get number of widgets so we can expect -1 later
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await pumpX(tester);
          await tester.longPress(find.text(Users.user1.name).first);
          await pumpX(tester);
          // todo tap on delete button
          await pumpX(tester);
          await tester.tap(find.text("YES"));
          await pumpX(tester);
          // todo expect that there is -1 chat
          expect(find.text("Test message"), findsAtLeastNWidgets(1));

          await pumpX(tester);

        },
      );
    },
  );
}
