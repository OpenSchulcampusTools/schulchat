import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';

import 'search_tile.dart';

class SearchDialog extends StatelessWidget {
  final Room room;

  const SearchDialog({Key? key, required this.room}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text(L10n.of(context)!.search),
      children: [
        SearchTile(room: room),
      ],
    );
  }
}
