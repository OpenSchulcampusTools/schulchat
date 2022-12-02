import 'dart:async';

import 'package:fluffychat/pages/chat_search/chat_search_view.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/cupertino.dart';
import 'package:matrix/matrix.dart';
import 'package:vrouter/vrouter.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

enum SearchState { searching, finished, noResult }

class ChatSearch extends StatefulWidget {
  const ChatSearch({Key? key}) : super(key: key);

  @override
  ChatSearchController createState() => ChatSearchController();
}

class ChatSearchController extends State<ChatSearch> {

  String? get roomId => VRouter.of(context).pathParameters['roomid'];
  Timeline? timeline;
  Room? room;

  Stream<List<Event>>? searchResultStream;
  final TextEditingController searchController = TextEditingController();
  String? searchError;
  SearchState searchState = SearchState.noResult;
  bool searchResultsFound = false;

  String _searchTerm = "";
  String _lastSearchTerm = "";
  List<String> _foundMessages = <String>[];

  final AutoScrollController scrollController = AutoScrollController();
  bool showScrollToTopButton = false;

  static const fixedWidth = 360.0;

  @override
  void initState() {
    scrollController.addListener(_updateScrollController);
    searchResultStream = _emptyList();

    super.initState();
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

  void _updateScrollController() {
    if (!scrollController.hasClients) return;

    if (scrollController.position.pixels > 0 && showScrollToTopButton == false) {
      setState(() => showScrollToTopButton = true);
    } else if (scrollController.position.pixels == 0 &&
        showScrollToTopButton == true) {
      setState(() => showScrollToTopButton = false);
    }
  }

  bool searchFunction(Event event) {
    // use _foundMessages to filter out messages which have already be found
    if (event.type == EventTypes.Message && !_foundMessages.contains(event.eventId)) {
      bool found = event.body.toLowerCase().contains(_searchTerm.toLowerCase());
      if(found) {
        _foundMessages.add(event.eventId);
        return found;
      }
    }

    return false;
  }

  void search() async {
    try {
      _searchTerm = searchController.text;

      // start search only if a new search term was entered
      if (_searchTerm != _lastSearchTerm) {

        _lastSearchTerm = _searchTerm;
        _foundMessages.clear();

        searchError = null;
        searchResultsFound = false;

        if (_searchTerm.isNotEmpty) {
          searchResultStream = timeline
              ?.searchEvent(
                  searchTerm: _searchTerm,
                  requestHistoryCount: 30,
                  maxHistoryRequests: 30,
                  searchFunc: searchFunction)
              .asBroadcastStream();

          searchState = SearchState.searching;
          searchResultStream?.listen(_listenToSearchStream,
              onDone: () => searchState = SearchState.finished,
              onError: (error) {
                searchState = SearchState.finished;
                searchError = L10n.of(context)?.searchError;
              },
              cancelOnError: true);
        } else {
          searchResultStream = _emptyList();
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

  void unfold(String eventId) {}

  void onSelectMessage(Event event) {
    scrollToEventId(event.eventId);
  }

  void scrollToEventId(String eventId) {
    VRouter.of(context).path.startsWith('/spaces/')
        ? VRouter.of(context).pop()
        : VRouter.of(context).toSegments(['rooms', roomId!],
        queryParameters: {'event': eventId});
  }

  void scrollToTop() {
    scrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fixedWidth,
      child: ChatSearchView(this),
    );
  }
}
