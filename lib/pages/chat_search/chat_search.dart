import 'package:fluffychat/pages/chat_search/chat_search_view.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/cupertino.dart';
import 'package:matrix/matrix.dart';
import 'package:vrouter/vrouter.dart';

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

  static const fixedWidth = 360.0;

  @override
  void initState() {
    super.initState();
    searchResultStream = _emptyList();
  }

  Future<bool> getTimeline() async {

    if(room == null) {
      room = Matrix.of(context).client.getRoomById(roomId!)!;
    }

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
      found = event.body.toLowerCase().contains(
          searchTerm.toLowerCase());
    }

    return found;
  }

  void search() async {
    try {
      searchError = null;

      searchTerm = searchController.text;

      if (searchTerm != lastSearchTerm) {

        setState(() {searchResultStream = _emptyList();});
        lastSearchTerm = searchTerm;

        if (searchTerm.isNotEmpty) {

        //  searchTerm = searchText;
          searchResultStream = timeline?.searchEvent(
              searchTerm: searchTerm,
              requestHistoryCount: 30,
              maxHistoryRequests: 30,
              searchFunc: searchFunc).asBroadcastStream();

          setState(() {});
        }

      }

    //  Navigator.of(context).pop();
    } catch (e) {
      searchError = "Bei der Suche ist ein Fehler aufgetreten.";
    }
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