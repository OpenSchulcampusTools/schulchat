import 'dart:async';

import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

import 'package:fluffychat/pages/chat/read_receipt/read_receipt_extension.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'read_receipt_overview_view.dart';

class ReadReceiptOverviewPage extends StatefulWidget {
  const ReadReceiptOverviewPage({Key? key}) : super(key: key);

  @override
  ReadReceiptOverviewController createState() =>
      ReadReceiptOverviewController();
}

class ExpansionPanelItem {
  List<Event> readReceiptRequests = [];
  List<Event> messages = [];
  bool messagesLoaded = false;
  Timeline? timeline;
  Room? room;
  bool isExpanded = false;
  StreamSubscription<List<Event>>? eventStreamSubscription;
  bool hasToGiveReadReceipt = false;

  ExpansionPanelItem(Room this.room);
}

class ReadReceiptOverviewController extends State<ReadReceiptOverviewPage> {
  Map<String, ExpansionPanelItem> panelItems = {};
  Map<String, Map<String, Event>> _localStorageEvents = {};
  bool roomsLoaded = false;
  Client? _client;

  void loadRooms() async {
    _client = Matrix.of(context).client;
    await _client!.roomsLoading;
    await _client!.accountDataLoading;
    await _client!.readReceiptRequestsLoading;

    for (final room in _client!.rooms) {
      if (!room.isSpace &&
          _client!.readReceiptRequests.keys.contains(room.id)) {
        _addPanelItem(room);
      }
    }

    _client!.newReadReceiptRequestCallback = _updateReadReceiptRequests;

    await _getEventsFromLocalStorage();

    // sort items, so rooms in which user has to give
    // read receipts are at the beginning
    _sortPanelItems();

    setState(() {
      panelItems;
      roomsLoaded = true;
    });
  }

  void _addPanelItem(Room room) {
    final panelItem = ExpansionPanelItem(room);
    panelItem.hasToGiveReadReceipt =
        _client!.roomsWithOpenReadReceipts.contains(room.id);
    panelItems.addAll({room.id: panelItem});
  }

  void _sortPanelItems() {
    final List<ExpansionPanelItem> sortedItems = panelItems.values.toList()
      ..sort((item1, item2) {
        if (item1.hasToGiveReadReceipt == item2.hasToGiveReadReceipt) {
          return 0;
        }
        // item1 < item 2
        else if (item1.hasToGiveReadReceipt && !item2.hasToGiveReadReceipt) {
          return -1;
        }
        // item 2 < item 1
        else {
          return 1;
        }
      });

    panelItems.clear();
    for (final ExpansionPanelItem item in sortedItems) {
      panelItems.addAll({item.room!.id: item});
    }
  }

  Future<void> _getEventsFromLocalStorage() async {
    final Map<String, Map>? localStorageEventsRaw =
        await _client!.database?.getReadReceiptRequiredEvents();

    if (localStorageEventsRaw != null) {
      for (final String key in localStorageEventsRaw.keys) {
        final split = key.split('|');
        if (split.length > 1 && localStorageEventsRaw[key] != null) {
          final Room? room =
              panelItems.tryGet<ExpansionPanelItem>(split[0])?.room;
          if (room != null) {
            final event =
                Event.fromJson(copyMap(localStorageEventsRaw[key]!), room);
            if (_localStorageEvents.containsKey(room.id)) {
              // if event.eventId exits already it is overwritten
              _localStorageEvents[room.id]!.addAll({event.eventId: event});
            } else {
              _localStorageEvents.addAll({
                room.id: {event.eventId: event}
              });
            }
          }
        }
      }
    }
  }

  void _updateOpenReadReceipt(ExpansionPanelItem panelItem) {
    panelItem.hasToGiveReadReceipt =
        _client!.roomsWithOpenReadReceipts.contains(panelItem.room!.id);
  }

  void _updateReadReceiptRequests(Room room, MatrixEvent event) async {
    // if room is not already in panelItems, add it
    if (!panelItems.containsKey(room.id)) {
      _addPanelItem(room);
    }

    if (panelItems[room.id]!.timeline == null) {
      panelItems[room.id]!.timeline =
          await _getTimeline(panelItems[room.id]!.room);
    }

    // then add new message
    for (final panelItem in panelItems.values) {
      if (panelItem.room!.id == room.id) {
        await _addParentToMessages(event, panelItem);

        setState(() {
          panelItem.messages;
          panelItem.hasToGiveReadReceipt =
              _client!.roomsWithOpenReadReceipts.contains(room.id);
        });

        break;
      }
    }

    _sortPanelItems();
    setState(() {
      panelItems;
    });
  }

  void _loadMessages(ExpansionPanelItem panelItem) async {
    if (!panelItem.messagesLoaded) {
      final String roomId = panelItem.room!.id;

      panelItem.timeline = await _getTimeline(panelItem.room);
      panelItem.messages.clear();

      if (_client!.readReceiptRequests.containsKey(roomId)) {
        for (final MatrixEvent mEvent
            in _client!.readReceiptRequests[panelItem.room!.id]!.values) {
          await _addParentToMessages(mEvent, panelItem);
        }
      }

      setState(() {
        panelItem.messagesLoaded = true;
        panelItem.messages;
      });
    }
  }

  Future<bool> _addParentToMessages(
      MatrixEvent mEvent, ExpansionPanelItem panelItem) async {
    final String? parentId = mEvent.content
        .tryGetMap<String, dynamic>('m.relates_to')
        ?.tryGet<String>("event_id");

    if (parentId != null) {
      final Room room = panelItem.room!;

      final Event? parentEvent = await _loadParentEvent(room, parentId);

      if (parentEvent != null) {
        // add related events as aggregated events to timeline
        await _addAggregatedEventsToTimeline(
            parentEvent, mEvent, panelItem.timeline!, room);

        // events from sync are sorted chronologically up
        // but we need latest event first -> therefore insert(0, ...
        panelItem.messages.insert(0, parentEvent);
        return true;
      }
    }

    return false;
  }

  Future<void> _addAggregatedEventsToTimeline(Event parentEvent,
      MatrixEvent aggregatedEvent, Timeline timeline, Room room) async {
    final relations = await parentEvent.getRelations();

    for (final relation in relations) {
      final Event eEvent = Event.fromMatrixEvent(relation, room);
      timeline.addAggregatedEvent(eEvent);
    }
  }

  Future<Timeline> _getTimeline(room) async {
    final timeline = await room!.getTimeline();
    // requests keys for all events in timeline
    timeline!.requestKeys(onlineKeyBackupOnly: false);
    return timeline;
  }

  Future<Event?> _loadParentEvent(Room room, String parentId) async {
    // check if event is already in local storage
    final Event? storageEvent = _localStorageEvents
        .tryGetMap<String, dynamic>(room.id)
        ?.tryGet<Event>(parentId);

    if (storageEvent == null) {
      final MatrixEvent parent =
          await room.client.getOneRoomEvent(room.id, parentId);

      final bool? isRedacted = parent.unsigned?.containsKey("redacted_by");
      if (isRedacted != true) {
        Event parentEvent = Event.fromMatrixEvent(parent, room);
        parentEvent = await _decryptEvent(parentEvent, room);

        // add parent to local storage
        await _client!.database
            ?.addReadReceiptRequiredEvent(parentEvent, room.id);
        return parentEvent;
      } else {
        return null;
      }
    } else {
      return storageEvent;
    }
  }

  Future<Event> _decryptEvent(Event parentEvent, Room room) async {
    if (parentEvent.type == EventTypes.Encrypted &&
        room.client.encryptionEnabled) {
      parentEvent =
          await room.client.encryption!.decryptRoomEvent(room.id, parentEvent);
      if (parentEvent.type == EventTypes.Encrypted ||
          parentEvent.messageType == MessageTypes.BadEncrypted ||
          parentEvent.content['can_request_session'] == true) {
        // Await requestKey() here to ensure decrypted message bodies
        await parentEvent.requestKey();
        parentEvent = await room.client.encryption!
            .decryptRoomEvent(room.id, parentEvent);
      }
    }
    return parentEvent;
  }

  void onReadReceiptClick(Event event, ExpansionPanelItem panelItem) async {
    final String? readReceiptEventId =
        await event.onReadReceiptIconClick(event, panelItem.timeline!, context);

    // if readReceiptEventId is !null, then the user has given a new read receipt
    if (readReceiptEventId != null) {
      final MatrixEvent readReceiptEvent = await panelItem.room!.client
          .getOneRoomEvent(panelItem.room!.id, readReceiptEventId);

      _addAggregatedEventsToTimeline(
          event, readReceiptEvent, panelItem.timeline!, panelItem.room!);

      await _client!.updateOpenReadReceipts(panelItem.room!.id);
      _updateOpenReadReceipt(panelItem);
      _sortPanelItems();

      setState(() {
        panelItems;
      });
    }
  }

  void expansionCallback(panelIndex, isExpanded) {
    if (panelItems.length > panelIndex) {
      final panelItem = panelItems.values.elementAt(panelIndex);

      setState(() {
        panelItem.isExpanded = !isExpanded;
      });

      if (!isExpanded) {
        _loadMessages(panelItem);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    loadRooms();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) => ReadReceiptOverviewView(this);
}
