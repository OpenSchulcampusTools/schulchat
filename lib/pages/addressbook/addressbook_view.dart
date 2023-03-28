import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';
import 'package:vrouter/vrouter.dart';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/widgets/layouts/max_width_body.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'addressbook.dart';

class AddressbookView extends StatelessWidget {
  const AddressbookView({
    super.key,
    required this.entry,
    required this.onTap,
    required this.toggleEntry,
    required this.isSelected,
    required this.selection,
    required this.displayBelowLastEntry,
    required this.displayAboveFirstEntry,
    required this.invite,
  });

  final TreeEntry<ABookEntry> entry;
  final VoidCallback onTap;
  final VoidCallback toggleEntry;
  final bool Function() isSelected;
  final Set<ABookEntry> selection;
  final bool Function(TreeEntry<ABookEntry>) displayBelowLastEntry;
  final bool Function(TreeEntry<ABookEntry>) displayAboveFirstEntry;
  final void Function(List<ABookEntry>, String) invite;

  @override
  Widget build(BuildContext context) {
    //IconButton? closeBtn;
    //Container? closeBtn;
    final children = <Widget>[];
    Room? room;
    String? roomName;
    final roomId = VRouter.of(context).pathParameters['roomid'];
    if (roomId != null) {
      room = Matrix.of(context).client.getRoomById(roomId)!;
      roomName = room.name.isEmpty ? L10n.of(context)!.group : room.name;
      print('in room: $roomId with name $roomName');
      // TODO add description (hover)
      //closeBtn = Container(
      //  alignment: Alignment.centerLeft,
      //  child: IconButton(
      //  icon: const Icon(Icons.close_outlined),
      //  onPressed: () => VRouter.of(context).toSegments(['rooms', roomId]),
      //  alignment: Alignment.centerLeft,
      //  )
      //);
    }
    late final Widget addressbook = InkWell(
      onTap: onTap,
      child: TreeIndentation(
        entry: entry,
        guide: const IndentGuide.connectingLines(indent: 48),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
          child: Row(
            // reduces the amount horizontally
            //mainAxisSize: MainAxisSize.min, //min?
            children: [
              FolderButton(
                isOpen: entry.hasChildren ? entry.isExpanded : null,
                onPressed: entry.hasChildren ? onTap : null,
              ),
              Text(
                entry.node.title,
                //            style: TextStyle(fontSize: 13 * AppConfig.fontSizeFactor),
              ),
              IconButton(
                icon: isSelected()
                    ? const Icon(Icons.check_box)
                    : const Icon(Icons.check_box_outline_blank),
                onPressed: toggleEntry,
              )
            ],
          ),
        ),
      ),
    );
    //if (closeBtn != null && displayAboveFirstEntry(entry)) {
    //  children.add(closeBtn);
    //  //children.add(Text(L10n.of(context)!.addressbook));
    //}
    final selectedEntries = <Widget>[];
    // main entries like Teacher, Student, Admins have a category
    final selectedWithoutCategory = <ABookEntry>[];
    for (final e in selection) {
      if (!e.category) {
        selectedWithoutCategory.add(e);
      }
    }
    if (selectedWithoutCategory.isNotEmpty &&
        roomId != null &&
        displayAboveFirstEntry(entry)) {
      // show the invite button only if there are selected entries
      children.add(Container(
        padding: const EdgeInsets.all(12.0),
        decoration:
            BoxDecoration(border: Border.all(color: Colors.green.shade800)),
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => invite(selectedWithoutCategory, roomId),
          label: Text(L10n.of(context)!.inviteFromAddressbook),
          icon: const Icon(Icons.library_add),
        ),
      ));
      children.add(
        const Divider(thickness: 3),
      );
    }
    children.add(SizedBox(height: 10));
    children.add(SizedBox(height: 10));
    children.add(SizedBox(height: 10));
    children.add(SizedBox(height: 10));
    children.add(SizedBox(height: 10));
    children.add(SizedBox(height: 10));

    if (displayBelowLastEntry(entry) && selection.isNotEmpty) {
      print('adding more entries below');
      for (final e in selectedWithoutCategory) {
        selectedEntries.add(
          Text(
            '${e.title} (${L10n.of(context)!.addressbookContext}: ${e.info})',
          ),
        );
      }
      //children.add(addressbook);
      children.add(Column(
        mainAxisSize: MainAxisSize.min, //min?
        children: [addressbook],
      ));
      children.add(const Divider(thickness: 3));
      children.add(Text(L10n.of(context)!.contactsOverview));
      //selection.forEach((e) {
      //  if (!e.category) {
      //    selectedEntries.add(Text('${e.title} (context: ${e.info})'));
      //  }
      //});
      //children.add(MaxWidthBody(
      //    child: Column(mainAxisSize: MainAxisSize.min,children: selectedEntries)));
      children.add(Column(
          mainAxisSize: MainAxisSize.min, //min?
          children: selectedEntries));
    } else {
      children.add(Column(
          mainAxisSize: MainAxisSize.min, //min?
          children: [addressbook]));
    }
//    return Column(children: children);
    return Scaffold(
        //backgroundColor: color,
        appBar: AppBar(
          leading: const BackButton(color: Colors.black),
          systemOverlayStyle: SystemUiOverlayStyle.light,
          //backgroundColor: Colors.transparent,
          backgroundColor:
              Theme.of(context).colorScheme.secondaryContainer.withAlpha(210),
          elevation: 0,
          title: Text(
            L10n.of(context)!.addressbook,
          ),
          actions: const [],
        ),
        extendBodyBehindAppBar: false,
        body: Container(
            color:
                Theme.of(context).colorScheme.secondaryContainer.withAlpha(210),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, //min?
              children: children,
            )));

//      body: MaxWidthBody(
////        withScrolling: true,
//        maxWidth: 800,
//        child: Container(
//          color: Theme.of(context).colorScheme.secondaryContainer.withAlpha(210),
//          child: Column(
//          mainAxisSize: MainAxisSize.min, //min?
//          children: children,)
//)));
  }
}
