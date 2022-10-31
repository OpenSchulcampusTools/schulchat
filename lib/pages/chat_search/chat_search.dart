import 'dart:async';

import 'package:fluffychat/pages/chat_search/chat_search_view.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/cupertino.dart';
import 'package:matrix/matrix.dart';
import 'package:vrouter/vrouter.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

enum SearchState {
  searching,
  finished,
  noResult
}

class ChatSearch extends StatefulWidget {
  const ChatSearch({Key? key}) : super(key: key);

  @override ChatSearchController createState() => ChatSearchController();
}

class ChatSearchController extends State<ChatSearch> {

  String? get roomId => VRouter.of(context).pathParameters['roomid'];
  Timeline? timeline;
  Room? room;
  Stream<List<Event>>? searchResultStream;
  final TextEditingController searchController = TextEditingController();
  String? searchError;
  String lastSearchTerm = "";
  SearchState searchState = SearchState.noResult;
  bool searchResultsFound = false;

  static const fixedWidth = 360.0;

  @override
  void initState() {
    super.initState();
    searchResultStream = _emptyList();
  }

  Future<bool> getTimeline() async {

    room ??= Matrix.of(context).client.getRoomById(roomId!)!;

    if (timeline == null) {

      await Matrix.of(context).client.roomsLoading;
      await Matrix.of(context).client.accountDataLoading;
      timeline = await room!.getTimeline();
    }

    timeline!.requestKeys();
    return true;
  }

  String searchTerm = "";
  bool searchFunc(Event event) {

    bool found = false;
    if(event.type == EventTypes.Message) {
      found = event.body.toLowerCase().contains(searchTerm.toLowerCase());
    }

    return found;
  }


  void search() async {
    try {

      searchError = null;
      searchTerm = searchController.text;

      // start search only if a new search word was entered
      if (searchTerm != lastSearchTerm) {

        lastSearchTerm = searchTerm;

        // set back UI
        searchResultsFound = false;
        searchState = SearchState.noResult;
        setState(() {});

        if (searchTerm.isNotEmpty) {

          searchResultStream = timeline?.searchEvent(
              searchTerm: searchTerm,
              requestHistoryCount: 30,
              maxHistoryRequests: 30,
              searchFunc: searchFunc).asBroadcastStream();

          searchState = SearchState.searching;
          searchResultStream?.listen(_listenToSearchStream,
              onDone: () => searchState = SearchState.finished,
              onError: (error) {
                  searchState = SearchState.finished;
                  searchError = L10n.of(context)?.searchError;
                  },
              cancelOnError: true
          );


        }
        else {
          searchResultStream = _emptyList().asBroadcastStream();
          searchState = SearchState.noResult;
        }

        setState(() {});
      }

    } catch (e) {
      searchError = L10n.of(context)?.searchError;
    }
  }

  void _listenToSearchStream(event) {
    searchResultsFound = true;
  }


  Stream<List<Event>> _emptyList() async* {
    yield <Event>[];
  }

  void unfold(String eventId) {

  }

  void onSelectMessage(Event event) {
    VRouter.of(context).path.startsWith('/spaces/')
        ? VRouter.of(context).pop()
        : VRouter.of(context)
        .toSegments(['rooms', roomId!], queryParameters: {'event': event.eventId});
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fixedWidth,
      child: ChatSearchView(this),
    );
  }
}