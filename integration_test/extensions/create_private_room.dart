import 'package:fluffychat/pages/chat/chat_view.dart';
import 'package:fluffychat/pages/chat_list/chat_list_body.dart';
import 'package:fluffychat/pages/chat_list/start_chat_fab.dart';
import 'package:fluffychat/widgets/profile_bottom_sheet.dart';
import 'package:fluffychat/widgets/chat_settings_popup_menu.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'wait_for.dart';
import '../users.dart';

extension PrivateRoomExtension on WidgetTester {
  // we dropped private chats in favour of rooms
  // keep this method in case we need it later
  Future<void> createPrivateRoom(localname) async {
    await pumpAndSettle();
    // New chat or Start first chat
    await waitFor(find.byType(StartChatFloatingActionButton));
    await tap(find.byType(StartChatFloatingActionButton));
    await pumpAndSettle();

    await waitFor(find.byType(TextFormField));
    await enterText(find.byType(TextFormField), '@$localname:$homeserver');
    await testTextInput.receiveAction(TextInputAction.done);
    await pumpAndSettle();
    await waitFor(
      find.descendant(
        of: find.byType(ProfileBottomSheet),
        matching: find.text('New chat'),
      ),
    );
    await tap(
      find.descendant(
        of: find.byType(ProfileBottomSheet),
        matching: find.text('New chat'),
      ),
    );

    await pumpAndSettle();
    await waitFor(find.byType(ChatView));
    await waitFor(find.text('💬 integration1 created the chat'));
    await waitFor(find.text('You joined the chat'));
    //FIXME this does not seem to be the default anymore?
    //await waitFor(find.text('🔐 integration1 activated end to end encryption'));
    await waitFor(find.text('📩 You invited $localname'));
    await pumpAndSettle();
  }

  // upstream worked on style for chat lists after 1.10
  // currently we have an overflow problem in chat_list so we do not use this until
  // we tested the upstream patches
  Future<void> createRoomWithInvite(localname) async {
    await pumpAndSettle();
    // New chat or Start first chat
    await waitFor(find.byType(StartChatFloatingActionButton));
    await tap(find.byType(StartChatFloatingActionButton));
    await pumpAndSettle();

    await waitFor(find.byType(FloatingActionButton));
    await tap(find.byType(FloatingActionButton));
    await pumpAndSettle();

    await pumpAndSettle();
    await waitFor(find.byType(ChatView));
    await waitFor(find.text('💬 integration1 created the chat'));
    await waitFor(find.text('You joined the chat'));
    await waitFor(find.text('🔐 integration1 activated end to end encryption'));
    await waitFor(find.byType(ChatSettingsPopupMenu));
    await tap(find.byType(ChatSettingsPopupMenu));
    await pumpAndSettle();
    await waitFor(find.text('Chat details'));
    await tap(find.text('Chat details'));
    await pumpAndSettle();
    // TODO invite is replaced by addressbook, which we cannot test with this setup yet
  }

  Future<void> openChat(localname) async {
    await pumpAndSettle();
    await enterText(find.byType(TextField).first, localname);
    await testTextInput.receiveAction(TextInputAction.done);
    await pumpAndSettle();
    await scrollUntilVisible(
      find.text('Chats').first,
      500,
      scrollable: find
          .descendant(
            of: find.byType(ChatListViewBody),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await waitFor(find.widgetWithText(ListTile, localname));
    await pumpAndSettle();
    await tap(find.widgetWithText(ListTile, localname));
    await pumpAndSettle();
  }

  Future<void> openChatByName(roomName) async {
    await pumpAndSettle();
    await waitFor(find.text(roomName));
    await tap(find.text(roomName));
    await pumpAndSettle();
  }

  Future<void> sendMessage(msg) async {
    await pumpAndSettle();
    await waitFor(
      find.descendant(
        of: find.byType(ChatView),
        matching: find.byType(TextField),
      ),
    );
    await enterText(
      find
          .descendant(
            of: find.byType(ChatView),
            matching: find.byType(TextField),
          )
          .last,
      msg,
    );
    await pumpAndSettle();
    await tap(find.byTooltip('Read receipt on'));
    await pumpAndSettle();
    await tap(find.byIcon(Icons.send_outlined));
    await pumpAndSettle();
    // wait 3 sec so that we don't find the text in the input field anymore
    // TODO: use a better finder in the ChatView
    await Future.delayed(const Duration(seconds: 10));
    await pumpAndSettle();
    await waitFor(
      find.text(msg),
      timeout: const Duration(seconds: 30),
    );
  }
}
