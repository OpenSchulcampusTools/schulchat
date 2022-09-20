import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/pages/chat/search_tile_view.dart';

class SearchTile extends StatefulWidget {
  final Room room;

  const SearchTile({Key? key, required this.room}) : super(key: key);

  @override
  State<SearchTile> createState() => SearchTileState();
}

class SearchTileState extends State<SearchTile> {
  final TextEditingController searchController = TextEditingController();

  String? searchError;
 // Timeline? timeline;

  @override
  void initState() {
    super.initState();
  }

  void search() async {
    try {
      searchError = null;

      final searchText = searchController.text;
      final room = widget.room;
      final timeline = await room.getTimeline();

      List<Event> searchResult = [];

      for (var i = 0; i < timeline.chunk.events.length; i++) {
        final event = timeline.chunk.events[i];
        if(event.type == EventTypes.Message ) {
          String? body = event.content["body"];
          if(body != null && body.toLowerCase().contains(searchText)) {
            searchResult.add(event);
          }
        }
      }

      setState(() {});

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Bei der Suche ist ein Fehler aufgetreten.")));
    }
  }

  @override
  Widget build(BuildContext context) => SearchTileView(controller: this);
}
