import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';

import 'package:fluffychat/pages/chat/search_tile.dart';

class SearchTileView extends StatelessWidget {
  final SearchTileState controller;

  const SearchTileView({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
     // mainAxisSize: MainAxisSize.min,
     // mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: controller.searchController,
            autofocus: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.label),
              label: Text(L10n.of(context)!.search),
              errorText: controller.searchError,
            ),
          ),
        ),
        ButtonBar(
          children: [
            TextButton(
              onPressed: controller.search,
              child: Text(L10n.of(context)!.search),
            ),
          ],
        )
      ],
    );
  }
}
