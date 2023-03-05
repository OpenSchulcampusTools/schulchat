import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/pages/chat/read_receipt/read_receipt_list_dialog.dart';
import '../../../widgets/matrix.dart';

/*
* returns eventId if a new ReadReceipt-event was created,
* otherwise returns null
 */
extension ReadReceiptExtension on Event {
  Future<String?> onReadReceiptIconClick(
      Event event, Timeline timeline, BuildContext context) async {
    String? eventId;

    final requiresReadReceipt = event
        .aggregatedEvents(timeline, RelationshipTypes.readReceiptRequired)
        .isNotEmpty;

    final String? userId = Matrix.of(context).client.userID;

    if (requiresReadReceipt && userId != null) {
      // if event was sent by current user
      if (event.senderId == userId) {
        showReadReceiptListDialog(context, event.room, timeline);
      } else {
        final userReadReceipt = event
            .aggregatedEvents(timeline, RelationshipTypes.readReceipt)
            .where((e) =>
                e.content
                    .tryGetMap<String, dynamic>('m.relates_to')
                    ?.tryGet<String>('user_id') ==
                userId)
            .toList();

        if (userReadReceipt.isEmpty) {
          eventId = await event.room.sendReadReceipt(event.eventId, userId);
        }
      }
    }

    return eventId;
  }

  void showReadReceiptListDialog(
          BuildContext context, Room room, Timeline timeline) =>
      showModalBottomSheet(
        context: context,
        builder: (context) => ReadReceiptListDialog(
          l10n: L10n.of(context)!,
          event: this,
          room: room,
          timeline: timeline,
        ),
      );
}
