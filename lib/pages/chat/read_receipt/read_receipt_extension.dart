import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/pages/chat/read_receipt/read_receipt_list_dialog.dart';

/*
* returns eventId if a new ReadReceipt-event was created,
* otherwise returns null
 */
extension ReadReceiptExtension on Event {
  bool get isNotOwnEvent => (senderId != room.client.userID);

  void showReadReceiptListDialog(BuildContext context, Timeline timeline) {
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

  Future<String?> giveReadReceipt(Timeline timeline) async {
    String? readReceiptEventId;
    final String? userID = room.client.userID;

    final requiresReadReceipt =
        aggregatedEvents(timeline, RelationshipTypes.readReceiptRequired)
            .isNotEmpty;

    if (requiresReadReceipt && userID != null) {
      final userReadReceipt =
          aggregatedEvents(timeline, RelationshipTypes.readReceipt)
              .where(
                (e) =>
                    e.content
                        .tryGetMap<String, dynamic>('m.relates_to')
                        ?.tryGet<String>('user_id') ==
                    userID,
              )
              .toList();

      if (userReadReceipt.isEmpty) {
        readReceiptEventId = await room.sendReadReceipt(eventId, userID);
      }
    }

    return readReceiptEventId;
  }
}
