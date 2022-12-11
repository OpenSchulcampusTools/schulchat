import 'package:flutter/cupertino.dart';

import 'package:matrix/matrix.dart';

import 'package:fluffychat/pages/chat/read_receipt/read_receipt_list_view.dart';

class ReadReceiptList extends StatefulWidget {
  final Event event;
  final Room room;
  final Timeline timeline;

  const ReadReceiptList(
      {required this.event,
      required this.room,
      required this.timeline,
      Key? key})
      : super(key: key);

  @override
  ReadReceiptListController createState() =>
      ReadReceiptListController(event, room, timeline);
}

class ReadReceiptListController extends State<ReadReceiptList> {
  Event? event;
  Room? room;
  Timeline? timeline;
  List<User> members = [];
  Set<Event>? readReceipts;
  String filter = "all";

  ReadReceiptListController(
      Event this.event, Room this.room, Timeline this.timeline);

  @override
  void initState() {
    members = room!.getParticipants();
    readReceipts =
        event!.aggregatedEvents(timeline!, RelationshipTypes.readReceipt);

    super.initState();
  }

  bool userHasGivenReadReceipt(int index) {
    bool found = false;
    final userId = members[index].id;

    for (final event in readReceipts!) {
      if (event.senderId == userId) {
        found = true;
      }
    }

    return found;
  }

  bool userIsVisible(int index) {
    // don't show user who has requested read receipt
    if (event!.senderId == members[index].id) {
      return false;
    } else if (filter == "all") {
      return true;
    } else {
      final hasReadReceipt = userHasGivenReadReceipt(index);
      if (filter == "open" && !hasReadReceipt ||
          filter == "given" && hasReadReceipt) {
        return true;
      } else {
        return false;
      }
    }
  }

  void changeFilter(value) {
    setState(() {
      filter = value.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ReadReceiptListView(this);
  }
}
