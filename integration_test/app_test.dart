import 'package:fluffychat/config/setting_keys.dart';
import 'package:fluffychat/pages/chat/chat_view.dart';
import 'package:fluffychat/pages/chat_list/chat_list_body.dart';
import 'package:fluffychat/pages/chat_list/search_title.dart';
import 'package:fluffychat/pages/invitation_selection/invitation_selection_view.dart';

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
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
      as IntegrationTestWidgetsFlutterBinding;
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
        final inviteLink = find.byType(TextField);
        await waitForFairkom(tester, inviteLink, findsOneWidget, 2000);
        await tester.enterText(inviteLink,
            "https://matrix.to/#/@${Users.user2.name}:devmh.fairmatrix.net");
        await tester.pump(const Duration(seconds: 2));
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await pumpX(tester);
        await tester.tap(find.widgetWithText(Row, 'New chat'));
        await pumpX(tester);
        expect(find.text('You joined the chat'), findsOneWidget);
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
          await tester.tap(find.text(Users.user2.name).first);
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

      testWidgets('Spaces', (tester) async {
        app.main();
        return;
        await tester.ensureAppStartedHomescreen();

        await tester.waitFor(find.byTooltip('Show menu'));
        await tester.tap(find.byTooltip('Show menu'));
        await tester.pumpAndSettle();

        await tester.waitFor(find.byIcon(Icons.workspaces_outlined));
        await tester.tap(find.byIcon(Icons.workspaces_outlined));
        await tester.pumpAndSettle();

        await tester.waitFor(find.byType(TextField));
        await tester.enterText(find.byType(TextField).last, 'Test Space');
        await tester.pumpAndSettle();

        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        await tester.waitFor(find.text('Invite contact'));

        await tester.tap(find.text('Invite contact'));
        await tester.pumpAndSettle();

        await tester.waitFor(
          find.descendant(
              of: find.byType(InvitationSelectionView),
              matching: find.byType(TextField)),
        );
        await tester.enterText(
          find.descendant(
              of: find.byType(InvitationSelectionView),
              matching: find.byType(TextField)),
          Users.user2.name,
        );

        await Future.delayed(const Duration(milliseconds: 250));
        await tester.testTextInput.receiveAction(TextInputAction.done);

        await Future.delayed(const Duration(milliseconds: 1000));
        await tester.pumpAndSettle();

        await tester.tap(find
            .descendant(
                of: find.descendant(
                  of: find.byType(InvitationSelectionView),
                  matching: find.byType(ListTile),
                ),
                matching: find.text(Users.user2.name))
            .last);
        await tester.pumpAndSettle();

        await tester.waitFor(find.maybeUppercaseText('Yes'));
        await tester.tap(find.maybeUppercaseText('Yes'));
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();

        await tester.waitFor(find.text('Load 2 more participants'));
        await tester.tap(find.text('Load 2 more participants'));
        await tester.pumpAndSettle();

        expect(find.text(Users.user2.name), findsOneWidget);
      });
    },
  );
}
