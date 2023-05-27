import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/pages/chat/read_receipt/read_receipt_list.dart';

extension ReadReceiptListDialogExtension on Event {
  void showReadReceiptListDialog(
    BuildContext context,
    Room room,
    Timeline timeline,
  ) =>
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.of(context)!.readReceipts),
        leading: IconButton(
          icon: const Icon(Icons.arrow_downward),
          onPressed: Navigator.of(context, rootNavigator: false).pop,
          tooltip: L10n.of(context)!.close,
        ),
      ),
      body: ReadReceiptList(event: event, room: room, timeline: timeline),
    );
  }
}
