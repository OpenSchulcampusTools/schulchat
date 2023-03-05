import 'dart:developer';

import 'package:fluffychat/pages/chat_list/chat_list_body.dart';
import 'package:fluffychat/pages/homeserver_picker/homeserver_picker.dart';
import 'package:fluffychat/pages/settings_account/settings_account_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../users.dart';
import 'wait_for.dart';

extension DefaultFlowExtensions on WidgetTester {
  Future<void> login({String? loginUsername, String? loginPassword}) async {
    final tester = this;

    await tester.pumpAndSettle();
    final inputTextField = find.byType(TextField);
    expect(inputTextField, findsOneWidget);
    await tester.enterText(inputTextField, 'devmh.fairmatrix.net');
    await tester.pumpAndSettle();

    await waitForFairkom(tester, find.text('Connect'), findsOneWidget, 10000);
    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    final inputs = find.byType(TextField);

    await tester.enterText(inputs.first, loginUsername ?? Users.user1.name);
    await tester.enterText(inputs.last, loginPassword ?? Users.user1.password);
    await tester.pumpAndSettle();
    await tester.testTextInput.receiveAction(TextInputAction.done);

    for (int i = 0; i < 10; i++) {
      // because pumpAndSettle doesn't work with riverpod
      await tester.pump(const Duration(seconds: 1));
    }

    expect(find.text('New chat'), findsOneWidget);
  }

  /// ensure PushProvider check passes
  Future<void> acceptPushWarning() async {
    final tester = this;

    final matcher = find.maybeUppercaseText('Do not show again');

    try {
      await tester.waitFor(matcher, timeout: const Duration(seconds: 5));

      // the FCM push error dialog to be handled...
      await tester.tap(matcher);
      await tester.pumpAndSettle();
    } catch (_) {}
  }

  Future<void> ensureLoggedOut() async {
    final tester = this;
    if (find.byType(ChatListViewBody).evaluate().isNotEmpty) {
      await tester.tap(find.byTooltip('Show menu'));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Settings'));
      await tester.pump(const Duration(seconds: 1));
      // await tester.scrollUntilVisible(
      //   find.text('Account'),
      //   500,
      //   scrollable: find.descendant(
      //     of: find.byKey(const Key('SettingsListViewContent')),
      //     matching: find.byType(Scrollable),
      //   ),
      // );
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Account'));
      await tester.pump(const Duration(seconds: 1));
      // await tester.scrollUntilVisible(
      //   find.text('Logout'),
      //   500,
      //   scrollable: find.descendant(
      //     of: find.byType(SettingsAccountView),
      //     matching: find.byType(Scrollable),
      //   ),
      // );
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Logout'));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.maybeUppercaseText('Yes'));
      await tester.pump(const Duration(seconds: 1));
    }
  }

  Future<void> ensureAppStartedHomescreen({
    Duration timeout = const Duration(seconds: 120), String? loginUsername, String? loginPassword,
  }) async {
    final tester = this;
    await tester.pumpAndSettle();

    final homeserverPickerFinder = find.byType(HomeserverPicker);
    final chatListFinder = find.byType(ChatListViewBody);

    final end = DateTime.now().add(timeout);

    log(
      'Waiting for HomeserverPicker or ChatListViewBody...',
      name: 'Test Runner',
    );
    do {
      if (DateTime.now().isAfter(end)) {
        throw Exception(
            'Timed out waiting for HomeserverPicker or ChatListViewBody');
      }

      await tester.pump(const Duration(seconds: 5));
      await Future.delayed(const Duration(milliseconds: 100));
    } while (homeserverPickerFinder.evaluate().isEmpty &&
        chatListFinder.evaluate().isEmpty);

    if (homeserverPickerFinder.evaluate().isNotEmpty) {
      log(
        'Found HomeserverPicker, performing login.',
        name: 'Test Runner',
      );
      await tester.login(loginUsername: loginUsername, loginPassword: loginPassword);
    } else {
      log(
        'Found ChatListViewBody, skipping login.',
        name: 'Test Runner',
      );
    }

   // await tester.acceptPushWarning();
  }
}
