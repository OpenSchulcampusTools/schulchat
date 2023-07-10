import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:vrouter/vrouter.dart';

import 'addressbook.dart';

class AddressbookView extends StatelessWidget {
  final AddressbookController controller;
  const AddressbookView(this.controller, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SliverAppBar? backBtn;

    // main entries like Teacher, Student, Admins have a category
    final selectedWithoutCategory = <ABookEntry>[];
    for (final e in controller.selection) {
      if (!e.category) {
        selectedWithoutCategory.add(e);
      }
    }

    // TODO add description (hover)
    backBtn = SliverAppBar(
      pinned: true,
      leading: BackButton(
        onPressed: () => controller.roomId != null
            ? VRouter.of(context).toSegments(['rooms', controller.roomId!])
            : Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_outlined, size: 16.0),
          onPressed: () => controller.loadAddressbook(true),
          tooltip: L10n.of(context)!.refreshContacts,
        ),
        if (selectedWithoutCategory.isNotEmpty &&
            controller.roomId != null &&
            !controller.invitesFromMultipleSchools())
          TextButton.icon(
            onPressed: () => controller.invite(
              selectedWithoutCategory,
              controller.roomId!,
            ),
            label: Text(L10n.of(context)!.inviteFromAddressbook),
            icon: const Icon(Icons.library_add),
          )
        else if (selectedWithoutCategory.isNotEmpty &&
            controller.roomId != null)
          Text(
            L10n.of(context)!.contactsFromMultipleSchoolsError,
            style: const TextStyle(color: Colors.red),
          )
      ],
      systemOverlayStyle: SystemUiOverlayStyle.light,
      backgroundColor:
          Theme.of(context).colorScheme.secondaryContainer.withAlpha(210),
      title: Text(L10n.of(context)!.addressbook),
    );

    final searchBar = SliverList(
      delegate: SliverChildListDelegate([
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
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              label: Text(
                L10n.of(context)!.abookSearchDesc,
              ),
            ),
          ),
        ),
      ]),
    );

    final List<Widget> searchResultArea = [];
    searchResultArea.add(
      SliverToBoxAdapter(
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                L10n.of(context)!.inviteSearchResults,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (controller.searchResults.isNotEmpty) {
      for (final e in controller.searchResults) {
        searchResultArea.add(
          SliverToBoxAdapter(
            child: Row(
              children: [
                if (e.active || e.kind == 'group')
                  IconButton(
                    icon: controller.isSelected(e)
                        ? const Icon(
                            Icons.check_circle_outline,
                            size: 16.0,
                          )
                        : const Icon(Icons.circle_outlined, size: 16.0),
                    onPressed: () => controller.toggleEntry(e),
                  ),
                Expanded(
                  child: Text(
                    (e.longName != null && e.longName!.isNotEmpty)
                        ? '${e.longName} (${e.info})'
                        : (e.kind == 'group')
                            ? '${e.title} (${e.info}) (${e.scgroupUsersActive!.length}/${e.scgroupUsersActive!.length + e.scgroupUsersInactive!.length})'
                            : '${e.title} (${e.info})',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      decoration: (e.active || e.kind == 'group')
                          ? TextDecoration.none
                          : TextDecoration.lineThrough,
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      }
    } else {
      searchResultArea.add(
        SliverToBoxAdapter(
          child: Row(
            children: [
              Text(
                L10n.of(context)!.noSearchResult,
              ),
            ],
          ),
        ),
      );
    }

    late final Widget addressbook = SliverTree<ABookEntry>(
      controller: controller.treeController,
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
                    if (entry.node.active ||
                        entry.node.category ||
                        entry.node.kind == 'group')
                      IconButton(
                        icon: controller.isSelected(entry.node)
                            ? const Icon(Icons.check_circle_outline, size: 16.0)
                            : const Icon(Icons.circle_outlined, size: 16.0),
                        onPressed: () => controller.toggleEntry(entry.node),
                        tooltip: L10n.of(context)!.selectContact,
                      ),
                    Expanded(
                      child: Text(
                        entry.node.longName != null &&
                                entry.node.longName!.isNotEmpty
                            ? entry.node.longName!
                            : (entry.node.kind == 'group')
                                ? '${entry.node.title} (${entry.node.scgroupUsersActive!.length}/${entry.node.scgroupUsersActive!.length + entry.node.scgroupUsersInactive!.length})'
                                : entry.node.title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          decoration: (entry.node.active ||
                                  entry.node.category ||
                                  entry.node.kind == 'group')
                              ? TextDecoration.none
                              : TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    return Scaffold(
      body: SizedBox(
        child: CustomScrollView(
          slivers: <Widget>[
            backBtn,
            searchBar,
            if (controller.showSearchResults)
              ...searchResultArea
            else
              addressbook,
            if (controller.selection.isNotEmpty) ...[
              const SliverToBoxAdapter(child: Divider(thickness: 3)),
              SliverToBoxAdapter(
                child: Text(
                  L10n.of(context)!.contactsOverview,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              for (final e in selectedWithoutCategory) ...[
                if (e.kind == 'group') ...[
                  SliverToBoxAdapter(
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.clear, size: 16.0),
                          onPressed: () => controller.toggleEntry(e),
                          tooltip: L10n.of(context)!.removeSelectionContact,
                        ),
                        Expanded(
                          child: Text(
                            '${e.title} (${e.info})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final groupMemberName in [
                    ...e.scgroupUsersActive!,
                    ...e.scgroupUsersInactive!
                  ]) ...[
                    if (!controller.deselectedUserEntries
                        .contains(groupMemberName)) ...[
                      SliverToBoxAdapter(
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.clear, size: 16.0),
                              onPressed: () async =>
                                  await controller.removeGroupMember(
                                e,
                                groupMemberName,
                              ),
                              tooltip: L10n.of(context)!.removeSelectionContact,
                            ),
                            Expanded(
                              child: Text(
                                '${controller.usersInSCGroups.where((u) => u.username == groupMemberName).toList().first.longName} (via ${e.title})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          ],
                        ),
                      )
                    ]
                  ]
                ] else ...[
                  SliverToBoxAdapter(
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.clear, size: 16.0),
                          onPressed: () => controller.toggleEntry(e),
                          tooltip: L10n.of(context)!.removeSelectionContact,
                        ),
                        Expanded(
                          child: Text(
                            (e.longName != null && e.longName!.isNotEmpty)
                                ? '${e.longName} (${e.info})'
                                : '${e.title} (${e.info})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )
                ]
              ]
            ] else
              ...[],
          ],
        ),
      ),
    );
  }
}
