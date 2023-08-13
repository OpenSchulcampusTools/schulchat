import 'package:flutter/cupertino.dart';

import 'package:matrix/matrix.dart';

import 'package:fluffychat/pages/chat/read_receipt/read_receipt_list_view.dart';

class ReadReceiptList extends StatefulWidget {
  final Event event;
  final Room room;
  final Timeline timeline;

  const ReadReceiptList({
    required this.event,
    required this.room,
    required this.timeline,
    Key? key,
  }) : super(key: key);

  @override
  ReadReceiptListController createState() => ReadReceiptListController();
}

class ReadReceiptListController extends State<ReadReceiptList> {
  late Event event;
  late Room room;
  late Timeline? timeline;
  List<User> members = [];
  List<MatrixEvent> readReceipts = [];
  String filter = "all";
  bool membersLoaded = false;

  void initReadReceipts() async {
    // use requestParticipants instead of getParticipants in case not all participants are yet loaded
    members = await room.requestParticipants([Membership.join]);

    members = members.where((user) {
      final membership = user.content.tryGet('membership');
      return (membership != null && membership == "join");
    }).toList();

    final origSrc = event.originalSource;
    Event origSrcEvt;
    String? origEvtId;
    if (origSrc != null) {
      // an edited event in chat view
      origSrcEvt = Event.fromMatrixEvent(origSrc, room);
      origEvtId = origSrcEvt.relationshipEventId;
    } else {
      // 1. edited event in overview (via settings) - this has a m.relates_to that refs the original event
      // 2. non-edit event in overview - has m.relates_to that references the read receipt request, so origEvtId isn't changed
      if (event.content
              .tryGetMap<String, dynamic>('m.relates_to')
              ?.tryGet<String>('rel_type') ==
          RelationshipTypes.edit) {
        origEvtId = event.relationshipEventId;
      }
    }

    // read all read receipts from server as there are possibly not all events already loaded in the timeline
    // receipt responses are related to the *original* event, so in case the message was edited,
    // we fetch the original event first
    if (origEvtId != null) {
      final Event? origEvent = await timeline!.getEventById(origEvtId);
      readReceipts =
          await origEvent!.getRelations(relType: RelationshipTypes.readReceipt);
    } else {
      readReceipts =
          await event.getRelations(relType: RelationshipTypes.readReceipt);
    }

    setState(() {
      members;
      readReceipts;
      membersLoaded = true;
    });
  }

  @override
  void initState() {
    event = widget.event;
    room = widget.room;
    timeline = widget.timeline;
    initReadReceipts();
    super.initState();
  }

  bool userHasGivenReadReceipt(int index) {
    bool found = false;
    final userId = members[index].id;

    for (final event in readReceipts) {
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
