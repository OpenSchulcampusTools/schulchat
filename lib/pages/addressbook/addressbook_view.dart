import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:vrouter/vrouter.dart';

import 'package:fluffychat/widgets/layouts/max_width_body.dart';
import 'addressbook.dart';

class AddressbookView extends StatelessWidget {
  final AddressbookController controller;
  const AddressbookView(this.controller, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    AppBar? backBtn;
    final String? roomId = VRouter.of(context).pathParameters['roomid'];

    // used for the radio button that selects active schools
    //String? selectedSchool = '';

    // main entries like Teacher, Student, Admins have a category
    final selectedWithoutCategory = <ABookEntry>[];
    for (final e in controller.selection) {
      if (!e.category) {
        selectedWithoutCategory.add(e);
      }
    }

    // TODO add description (hover)
    backBtn = AppBar(
      leading: Container(
        alignment: Alignment.centerLeft,
        child: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => roomId != null
              ? VRouter.of(context).toSegments(['rooms', roomId])
              : Navigator.of(context).pop(),
          alignment: Alignment.centerLeft,
        ),
      ),
      actions: (selectedWithoutCategory.isNotEmpty && roomId != null)
          ? [
              TextButton.icon(
                onPressed: () =>
                    controller.invite(selectedWithoutCategory, roomId),
                label: Text(L10n.of(context)!.inviteFromAddressbook),
                icon: const Icon(Icons.library_add),
              )
            ]
          : [],
      systemOverlayStyle: SystemUiOverlayStyle.light,
      backgroundColor:
          Theme.of(context).colorScheme.secondaryContainer.withAlpha(210),
      title: Text(L10n.of(context)!.addressbook),
    );

    final searchBar = Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: controller.searchController,
            onChanged: (value) {
              controller.search();
            },
            onSubmitted: (value) {
              controller.search();
            },
            autofocus: false,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              label: Text('Suche nach Personen und Gruppen'),
            ),
          ),
        ),
      ],
    );

    final Widget searchResult = Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: const Text(
            'Suchergebnisse',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        controller.searchResults.isNotEmpty
            ? Column(
                children: [
                  for (var e in controller.searchResults)
                    Row(
                      children: [
                        Text(
                          (e.longName != null && e.longName!.isNotEmpty)
                              ? '${e.longName} (${e.info})'
                              : '${e.title} (${e.info})',
                        ),
                        IconButton(
                          icon: controller.isSelected(e)
                              ? const Icon(Icons.check_box)
                              : const Icon(Icons.check_box_outline_blank),
                          onPressed: () => controller.toggleEntry(e),
                        )
                      ],
                    )
                ],
              )
            : Column(
                children: [Text(L10n.of(context)!.noSearchResult)],
              ),
      ],
    );
    late final Widget addressbook = SizedBox(
      child: TreeView<ABookEntry>(
        shrinkWrap: true,
        treeController: controller.treeController,
        nodeBuilder: (BuildContext context, TreeEntry<ABookEntry> entry) {
          return InkWell(
            onTap: () => controller.onTap(entry),
            child: TreeIndentation(
              entry: entry,
              guide: const IndentGuide.connectingLines(indent: 48),
              child: Padding(
                //padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
                padding: const EdgeInsets.all(0),
                child: Container(
                  color: Theme.of(context)
                      .colorScheme
                      .secondaryContainer
                      .withAlpha(210),
                  child: Row(
                    // reduces the amount horizontally
                    //mainAxisSize: MainAxisSize.min,
                    children: [
                      FolderButton(
                        isOpen: entry.hasChildren ? entry.isExpanded : null,
                        onPressed: entry.hasChildren
                            ? () => controller.onTap(entry)
                            : null,
                      ),
                      Text(
                        entry.node.longName != null &&
                                entry.node.longName!.isNotEmpty
                            ? entry.node.longName!
                            : entry.node.title,
                      ),
                      IconButton(
                        icon: controller.isSelected(entry.node)
                            ? const Icon(Icons.check_box)
                            : const Icon(Icons.check_box_outline_blank),
                        onPressed: () => controller.toggleEntry(entry.node),
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    return Scaffold(
      appBar: backBtn,
      extendBodyBehindAppBar: false,
      body: MaxWidthBody(
        withScrolling: true,
        maxWidth: 800,
        child: Column(
          children: [
            //for (final s in controller.listOfSchools) ...[
            //  RadioListTile(
            //      title: Text('Auswahl begrenzen auf ${s.title}'),
            //      value: s.title,
            //      groupValue: selectedSchool,
            //      onChanged: (String? value) {
            //        print('setting value in onChanged for $value');
            //        // if active, we are going to deactivate it now
            //        final buttonActive =
            //            s.title == selectedSchool ? true : false;
            //        controller.toggleSchool(s, !buttonActive);
            //        selectedSchool = value;
            //      }),
            //],
            searchBar,
            controller.showSearchResults ? searchResult : addressbook,
            if (controller.selection.isNotEmpty) ...[
              const Divider(thickness: 3),
              Text(L10n.of(context)!.contactsOverview),
              Column(
                children: [
                  for (final e in selectedWithoutCategory) ...[
                    Row(
                      children: [
                        Text(
                          (e.longName != null && e.longName!.isNotEmpty)
                              ? '${e.longName} (${e.info})'
                              : '${e.title} (${e.info})',
                        ),
                        IconButton(
                          icon: controller.isSelected(e)
                              ? const Icon(Icons.check_box)
                              : const Icon(Icons.check_box_outline_blank),
                          onPressed: () => controller.toggleEntry(e),
                        )
                      ],
                    )
                  ]
                ],
              )
            ] else
              ...[],
          ],
        ),
      ),
    );
  }
}
