import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/chat_details/participant_list_item.dart';

extension ReadReceiptListDialogExtension on Event {
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

class ReadReceiptListDialog extends StatelessWidget {
  final Event event;
  final L10n l10n;
  final Room room;
  final Timeline timeline;

  const ReadReceiptListDialog({
    required this.event,
    required this.l10n,
    required this.room,
    required this.timeline,
    Key? key,
  }) : super(key: key);

  bool _userHasGivenReadReceipt(Set<Event> readReceipts, String userId) {
    bool found = false;
    readReceipts.forEach((event) {
      if (event.senderId == userId) {
        found = true;
      }
    });

    return found;
  }

  @override
  Widget build(BuildContext context) {
    final List<User> members = room.getParticipants();
    final Set<Event> readReceipts =
        event.aggregatedEvents(timeline, RelationshipTypes.readReceipt);

    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.of(context)!.readReceipts),
        leading: IconButton(
          icon: const Icon(Icons.arrow_downward),
          onPressed: Navigator.of(context, rootNavigator: false).pop,
          tooltip: L10n.of(context)!.close,
        ),
      ),
      body: ListView.builder(
        itemCount: members.length,
        itemBuilder: (BuildContext context, int i) => Row(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 18),
                child: _userHasGivenReadReceipt(readReceipts, members[i].id)
                    ? const Icon(Icons.mark_chat_read,
                        color: AppConfig.primaryColor)
                    : const Icon(Icons.mark_chat_read_outlined,
                        color: AppConfig.primaryColor),
              ),
              Expanded(child: ParticipantListItem(members[i]))
            ]),
      ),
    );
  }
}
