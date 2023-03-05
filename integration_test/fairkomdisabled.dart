import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:fluffychat/main.dart' as app;

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

  group('Integration Test', () {
    testWidgets('Test if login works', (WidgetTester tester) async {
      final findHS = find.byType(TextField);
      final findConnect = find.text('Connect');
      final findCreds = find.byType(TextField);
      final findLogin = find.text('Login');
      final findNewchat = find.text('New chat');

      app.main();
      await waitFor(tester, findHS, findsOneWidget, 10000);
      await tester.enterText(findHS, 'devmh.fairmatrix.net');

      await waitFor(tester, findConnect, findsOneWidget, 10000);
      await tester.tap(findConnect);

      await waitFor(tester, findCreds, findsNWidgets(2), 10000);
      await tester.enterText(findCreds.first, Users.user1.name);
      await tester.enterText(findCreds.last, Users.user1.password);
      //////await tester.testTextInput.receiveAction(TextInputAction.done);
      await waitFor(tester, findLogin, findsOneWidget, 10000);
      await tester.tap(findLogin);

      //TODO this is bad and doesnt work! Find another way to set permissions
      //await waitFor(tester, find.text('Allow'), findsOneWidget, 10000);

      await waitFor(tester, findNewchat, findsOneWidget, 10000);
      expect(find.text('New chat'), findsOneWidget);
      expect(find.text('Login'), findsNothing); //TODO ensure room list loads

      await tester.tap(find.text('New chat'));
      final inviteLink = find.byType(TextField);
      await waitFor(tester, inviteLink, findsOneWidget, 10000);
      await tester.enterText(
          inviteLink, "https://matrix.to/#/@testuser1:devmh.fairmatrix.net");
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await waitFor(tester, find.text('New chat'), findsOneWidget, 10000);
      await tester.tap(find.text('New chat'));
      expect(find.text('You joined the chat'), findsOneWidget);
    }, semanticsEnabled: false);

    // testWidgets('Test if New Chat works', (WidgetTester tester) async {
    //   final findNewchat = find.text('New chat');
    //   tester.tap(findNewchat);
    //   final inviteLink = find.byType(TextField);
    //   await waitFor(tester, inviteLink, findsOneWidget, 10000);
    //   await tester.enterText(
    //       inviteLink, 'https://matrix.to/#/@testuser1:devmh.fairmatrix.net');
    //   await tester.testTextInput.receiveAction(TextInputAction.done);
    //   await waitFor(tester, findNewchat, findsOneWidget, 10000);
    //   tester.tap(findNewchat);
    //   expect(find.text('You joined the chat'), findsOneWidget);
    // }, semanticsEnabled: false);
  });
}
