import 'dart:developer';

import 'package:fluffychat/pages/chat/chat_view.dart';
import 'package:fluffychat/pages/chat_list/chat_list_body.dart';
import 'package:fluffychat/pages/chat_list/client_chooser_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../users.dart';
import 'wait_for.dart';

extension DefaultFlowExtensions on WidgetTester {
  Future<void> login({String? loginUsername, String? loginPassword}) async {
    final tester = this;

    await tester.pumpAndSettle();
    await tester.tap(find.text("Let's start"));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    final inputs = find.byType(TextField);

    await tester.enterText(inputs.first, loginUsername ?? Users.user1.name);
    await tester.enterText(inputs.last, loginPassword ?? Users.user1.password);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    try {
      // pumpAndSettle does not work in here as setState is called
      // asynchronously
      await tester.waitFor(
        find.byType(LinearProgressIndicator),
        timeout: const Duration(milliseconds: 1500),
        skipPumpAndSettle: true,
      );
    } catch (_) {
      // in case the input action does not work on the desired platform
      if (find.text('Login').evaluate().isNotEmpty) {
        await tester.tap(find.text('Login'));
      }
    }

    try {
      await tester.pumpAndSettle();
    } catch (_) {
      // may fail because of ongoing animation below dialog
    }

    final chatListViewBodyFinder = find.byType(ChatListViewBody);
    final acceptPushFinder = find.maybeUppercaseText('Do not show again');

    final end = DateTime.now().add(const Duration(seconds: 30));
    do {
      if (DateTime.now().isAfter(end)) {
        throw Exception('Timed out waiting push warning and chat list view');
      }
      try {
        await tester.pumpAndSettle();
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (_) {}
    } while (chatListViewBodyFinder.evaluate().isEmpty &&
        acceptPushFinder.evaluate().isEmpty);

    if (acceptPushFinder.evaluate().isNotEmpty) {
      await tester.acceptPushWarning();
    }
    await tester.waitFor(
      chatListViewBodyFinder,
      skipPumpAndSettle: true,
    );
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
    await pumpAndSettle();
    // only try to log out if we are actually logged in
    if (find.byType(ChatListViewBody).evaluate().isNotEmpty ||
        find.byType(ChatView).evaluate().isNotEmpty) {
      // if a chat view is visible and the screen is small enough or we are on native
      // clients, we need to go to the chat list view first, ie close the chat view
      if (find.byType(BackButton).evaluate().isNotEmpty) {
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
      }
      // if a user search is happening, close it first
      if (find.byTooltip('Cancel').evaluate().isNotEmpty) {
        await tester.tap(find.byTooltip('Cancel'));
        //tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
      }
//    if (find.byType(ChatListViewBody).evaluate().isNotEmpty) {
      await tester.waitFor(find.byType(ClientChooserButton));
      await tester.tap(find.byType(ClientChooserButton));
      await tester.pumpAndSettle();
      await tester.waitFor(find.text('Settings'));
      await tester.tap(find.text('Settings'));
      //await tester.pumpAndSettle();
      //workaround because chat backup message does not load if not configured
      //await Future.delayed(const Duration(milliseconds: 5000));
      //await tester.waitFor(find.text('Logout'));
      await tester.waitFor(
        find.text('Logout'),
        skipPumpAndSettle: true,
      );
      await tester.tap(find.text('Logout'));
      // use a small delay after hitting logout
      await Future.delayed(const Duration(milliseconds: 500));
      //await tester.pumpAndSettle();
      await tester.waitFor(
        find.maybeUppercaseText('logout'),
        skipPumpAndSettle: true,
      );
      await tester.tap(find.maybeUppercaseText('logout'));
      await tester.pumpAndSettle();
//    }
    }
  }

  Future<void> ensureAppStartedHomescreen({
    Duration timeout = const Duration(seconds: 120),
    String? loginUsername,
    String? loginPassword,
  }) async {
    final tester = this;

    await tester.pumpAndSettle();
    final chatListFinder = find.byType(ChatListViewBody);
    final letsStartFinder = find.text("Let's start");

    final end = DateTime.now().add(timeout);

    log(
      'Waiting for Lets start or ChatListViewBody...',
      name: 'Test Runner',
    );
    do {
      if (DateTime.now().isAfter(end)) {
        throw Exception('Timed out waiting for Lets start or ChatListViewBody');
      }

      await tester.pumpAndSettle();
      await Future.delayed(const Duration(milliseconds: 100));
    } while (letsStartFinder.evaluate().isEmpty &&
        chatListFinder.evaluate().isEmpty);

    if (letsStartFinder.evaluate().isNotEmpty) {
      log(
        'Found Lets start, performing login.',
        name: 'Test Runner',
      );
      await tester.login(
        loginUsername: loginUsername,
        loginPassword: loginPassword,
      );
    } else {
      log(
        'Found ChatListViewBody, skipping login.',
        name: 'Test Runner',
      );
    }

    await tester.acceptPushWarning();
  }
}
