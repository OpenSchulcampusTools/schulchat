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
  List<Event> searchResult = [];
  final TextEditingController searchController = TextEditingController();
  String? searchError;

  static const fixedWidth = 360.0;

  void search() async {
    try {
      searchError = null;

      final searchText = searchController.text;
      final room = Matrix.of(context).client.getRoomById(roomId!)!;
      final timeline = await room.getTimeline();

      searchResult = [];

      if(!searchText.isEmpty) {
        for (var i = 0; i < timeline.chunk.events.length; i++) {
          final event = timeline.chunk.events[i];
          if (event.type == EventTypes.Message) {
            String? body = event.content["body"];
            if (body != null && body.toLowerCase().contains(searchText)) {
              searchResult.add(event);
            }
          }
        }
      }

      setState(() {});

    //  Navigator.of(context).pop();
    } catch (e) {
      searchError = "Bei der Suche ist ein Fehler aufgetreten.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fixedWidth,
      child: ChatSearchView(this),
    );
  }
}