import 'package:fluffychat/config/setting_keys.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';

import 'package:fluffychat/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

import 'extensions/default_flows.dart';
import 'extensions/wait_for.dart';
import 'extensions/create_private_room.dart';
import 'extensions/leave_rooms.dart';
import 'users.dart';
import 'dart:math';

/*
TODO:
 - chat backup (after first login, click settings->chat backup; store the recovery key in a group scoped variable so it can be accessed from all remaining tests), during later logins ensure the recovery key is set
 - login via SC (needs another oauth2 client, hard coded domain)

*/

String random(int length) {
  var rand = Random();
  return String.fromCharCodes(
    List.generate(length, (index) => rand.nextInt(33) + 89),
  );
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.testTextInput.register(); // makes enterText work

  final uniqueMessage = 'Test message ${random(10)}';

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
        'Login as user 1, logout',
        //'Login as user 1, leave all chats, logout',
        (WidgetTester tester) async {
          app.main();
          await tester.ensureLoggedOut();
          await tester.ensureAppStartedHomescreen(
            loginUsername: Users.user1.name,
            loginPassword: Users.user1.password,
          );
//          await tester.leaveAllRooms();
//          await tester.removeAllDevices(Users.user1.password);
          await tester.ensureLoggedOut();
        },
        semanticsEnabled: false,
      );

      testWidgets(
        'Login as user 2, logout',
        //'Login as user 2, leave all chats, logout',
        (WidgetTester tester) async {
          app.main();
          await tester.ensureLoggedOut();
          await tester.ensureAppStartedHomescreen(
            loginUsername: Users.user2.name,
            loginPassword: Users.user2.password,
          );
//          await tester.leaveAllRooms();
//          await tester.removeAllDevices(Users.user2.password);
          await tester.ensureLoggedOut();
        },
        semanticsEnabled: false,
      );

      //testWidgets('User 1 starts a new chat with user 2',
      //    (WidgetTester tester) async {
      //  app.main();
      //  await tester.ensureLoggedOut();
      //  await tester.ensureAppStartedHomescreen(
      //    loginUsername: Users.user1.name,
      //    loginPassword: Users.user1.password,
      //  );
      //  await tester.createRoomWithInvite(Users.user2.name);
      //  await tester.ensureLoggedOut();
      //},
      //  semanticsEnabled: false,
      //);

      testWidgets(
        'User 2 accepts invite',
        (WidgetTester tester) async {
          app.main();
          await tester.ensureLoggedOut();
          await tester.ensureAppStartedHomescreen(
            loginUsername: Users.user2.name,
            loginPassword: Users.user2.password,
          );
          await tester.openChatByName('room with ${Users.user1.name}');
          await tester.ensureLoggedOut();
        },
        semanticsEnabled: false,
      );

      testWidgets(
        'User 1 sends a message with read receipt',
        (WidgetTester tester) async {
          app.main();
          await tester.ensureLoggedOut();
          await tester.ensureAppStartedHomescreen(
            loginUsername: Users.user1.name,
            loginPassword: Users.user1.password,
          );
          await tester.openChatByName('room with ${Users.user1.name}');
          await tester.sendMessage(uniqueMessage);
          await tester.ensureLoggedOut();
        },
        semanticsEnabled: false,
      );

      testWidgets(
        'User 2 checks if message was received',
        (WidgetTester tester) async {
          app.main();
          await tester.ensureLoggedOut();
          await tester.ensureAppStartedHomescreen(
            loginUsername: Users.user2.name,
            loginPassword: Users.user2.password,
          );
          await tester.openChatByName('room with ${Users.user1.name}');
          await tester.waitFor(find.text(uniqueMessage));
          // TODO click on open Lesebestätigung
        },
        semanticsEnabled: false,
      );
    },
  );
}
