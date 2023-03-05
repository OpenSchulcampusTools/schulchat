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
  Event event;
  Room room;
  Timeline? timeline;
  List<User> members = [];
  List<MatrixEvent>? readReceipts;
  String filter = "all";
  bool membersLoaded = false;

  ReadReceiptListController(this.event, this.room, Timeline this.timeline);

  void initReadReceipts() async {
    // use requestParticipants instead of getParticipants in case not all participants are yet loaded
    members = await room.requestParticipants([Membership.join]);

    members = members.where((user) {
      final membership = user.content.tryGet('membership');
      return (membership != null && membership == "join");
    }).toList();

    // read all read receipts from server as there are possibly not all events already loaded in the timeline
    readReceipts =
        await event.getRelations(relType: RelationshipTypes.readReceipt);

    setState(() {
      members;
      readReceipts;
      membersLoaded = true;
    });
  }

  @override
  void initState() {
    initReadReceipts();
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
    if (event.senderId == members[index].id) {
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
