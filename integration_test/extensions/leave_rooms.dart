import 'package:fluffychat/pages/chat/chat_view.dart';
import 'package:fluffychat/widgets/chat_settings_popup_menu.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'wait_for.dart';

// New chat vs. Start your first chat
// raum schließen: -> Show menu -> Leave -> OK(maybeuppercase)
// FIXME does not support creating a new chat yet, so the tests will fail if we use new users
// if there is no ChatView, we should fill in the invite link
// and click "Create new room"
extension LeaveAllRoomsExtension on WidgetTester {
  Future<void> leaveRoom() async {
    await waitFor(find.byType(ChatSettingsPopupMenu));
    await tap(find.byType(ChatSettingsPopupMenu));
    await pumpAndSettle();
    await waitFor(find.text('Leave'));
    // in case of empty chats there is the option to Reopen or Leave the chat
    // this means there are multiple Leave texts, that's why we always choose the last
    await tap(find.text('Leave').last);
    await pumpAndSettle();
    await waitFor(find.maybeUppercaseText('Ok'));
    await tap(find.maybeUppercaseText('Ok'));
    await pumpAndSettle();
  }

  Future<void> leaveAllRooms() async {
    // chatview is already open
    if (find.byType(ChatView).evaluate().isNotEmpty) {
      await leaveRoom();
    }
    // enter any remaining chats and leave them
    // Avatar's tap only marks the chat (like a long press), so we use Row
    final chats =
        find.descendant(of: find.byType(ListTile), matching: find.byType(Row));
    while (chats.evaluate().isNotEmpty) {
      await waitFor(chats);
      await tap(chats.first);
      //  await tap(find.byType(ListTile).first);
      await pumpAndSettle();
      if (find
          .text(
            "Can't join remote room because no servers that are in the room have been provided.",
          )
          .evaluate()
          .isNotEmpty) {
        await tap(find.maybeUppercaseText('Close'));
        await pumpAndSettle();
      } else {
        await waitFor(find.byType(ChatView));
        await leaveRoom();
      }
    }
  }
}
