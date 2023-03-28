import 'dart:convert';
import 'dart:core';

import 'package:flutter/material.dart';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart';

import 'package:fluffychat/widgets/matrix.dart';
import 'addressbook_view.dart';

class AddressbookPage extends StatefulWidget {
  const AddressbookPage({Key? key}) : super(key: key);

  @override
  State<AddressbookPage> createState() => AddressbookController();
}

class ABookEntry {
  const ABookEntry({
    required this.title,
    this.children = const <ABookEntry>[],
    this.id,
    this.category = false,
    this.info,
  });

  final String title;
  final List<ABookEntry> children;
  /*
     student: id is not needed (use username)
     parent: id is not needed (use username)
     teacher: id is not needed (use username)
     admins: id is not needed (use username)
     scgroup: id is needed
  */
  final String? id;
  // indicates not an actual value, like school or "teacher" group
  final bool category;
  // additional info (like category of the node, e.g. Teacher in school X)
  final String? info;
}

class AddressbookController extends State<AddressbookPage> {
  var abook = <ABookEntry>[];
  // mainly to wrap async, because initState cannot be async
  void loadAddressbook() async {
    abook = await buildAddressbook();
    setState(() {
      treeController.roots = abook;
      treeController.rebuild();
    });
  }

  Set<ABookEntry> get selection => selectedNodes;

  bool isSelected(ABookEntry node) {
    return selection.contains(node);
  }

  // holds all selected nodes
  // if a node has children, all childs are implicitly selected
  final Set<ABookEntry> selectedNodes = {};

  //true means select, false means remove
  void toggleRecursive(node, [state = true]) {
    (state == true) ? selection.add(node) : selection.remove(node);
    if (node.children.length > 0) {
      node.children.forEach((ABookEntry c) {
        (state == true) ? selection.add(c) : selection.remove(c);
        if (c.children.isNotEmpty) {
          toggleRecursive(c, state);
        }
      });
    }
  }

  void toggleEntry(node) {
    // remove a node if it is already selected
    if (selection.contains(node)) {
      toggleRecursive(node, false);
    } else {
      toggleRecursive(node, true);
    }

    setState(() {
      treeController.rebuild();
    });
  }

  Future<List<ABookEntry>> buildAddressbook() async {
    // temp HACK for showcase in case of integration1, set idm user to m.hannich
    final userId =
        (Matrix.of(context).client.userID!.localpart == 'integration1' ||
                Matrix.of(context).client.userID!.localpart == 'm.h')
            ? 'm.hannich'
            : Matrix.of(context).client.userID!.localpart;
    const url = 'http://localhost:8085/u/m.hannich/addressbook';
    final abookJson =
        json.decode(utf8.decode((await http.get(Uri.parse(url))).bodyBytes));
    //final abookJson = await Matrix.of(context).client.request(RequestType.GET, '/../idm/u/${userId}/addressbook');
    final abookEntries = <ABookEntry>[];
    abookJson.keys.forEach((school) {
      final schoolName = abookJson[school]['name'];
      //final schoolName = await Matrix.of(context).client.request(RequestType.GET, '/../idm/school/${school}');
      final abookSchool =
          ABookEntry(title: schoolName, children: [], category: true);
      final abookTeacher =
          ABookEntry(title: 'Lehrkräfte', children: [], category: true);
      final abookSCGroups = ABookEntry(
        title: 'Schulcampus-Gruppen',
        children: [],
        category: true,
      );
      final abookStudents =
          ABookEntry(title: 'Schüler:innen', children: [], category: true);
      final abookParents =
          ABookEntry(title: 'Sorgeberechtigte', children: [], category: true);
      final abookAdmins =
          ABookEntry(title: 'Admins', children: [], category: true);
      if (abookJson[school]['teachers']) {
        abookSchool.children.add(abookTeacher);
        abookJson[school]['teachers'].forEach((teacher) {
          abookTeacher.children.add(
            ABookEntry(
              title: teacher,
              info: '${L10n.of(context)!.contactsInfoTeacher} $schoolName',
            ),
          );
        });
      }
      if (abookJson[school]['scgroups']) {
        abookSchool.children.add(abookSCGroups);
        abookJson[school]['scgroups'].forEach((id, name) {
          abookSCGroups.children.add(
            ABookEntry(
              title: name,
              id: id,
              info: '${L10n.of(context)!.contactsInfoGroup} $schoolName',
            ),
          );
        });
      }
      if (abookJson[school]['students']) {
        abookSchool.children.add(abookStudents);
        abookJson[school]['students'].forEach((student) {
          abookStudents.children.add(
            ABookEntry(
              title: student,
              info: '${L10n.of(context)!.contactsInfoStudent} $schoolName',
            ),
          );
        });
      }
      if (abookJson[school]['parents']) {
        abookSchool.children.add(abookParents);
        abookJson[school]['parents'].forEach((parent) {
          abookParents.children.add(
            ABookEntry(
              title: parent,
              info: '${L10n.of(context)!.contactsInfoParent} $schoolName',
            ),
          );
        });
      }
      if (abookJson[school]['admins']) {
        abookSchool.children.add(abookAdmins);
        abookJson[school]['admins'].forEach((admin) {
          abookAdmins.children.add(
            ABookEntry(
              title: admin,
              info: '${L10n.of(context)!.contactsInfoAdmin} $schoolName',
            ),
          );
        });
      }
      abookEntries.add(abookSchool);
    });
    return abookEntries;
  }

  late final TreeController<ABookEntry> treeController;

  // gets a list of user and group ids and tries to invite them
  // returns a Set of success/failure per id
  void invite(invitees, roomId) async {
    // selection can contain the same user multiple times
    final uniqUsers = Set();
    final uniqGroups = Set();
    for (final e in selection) {
      if (e.id != null) {
        uniqGroups.add(e);
      } else {
        uniqUsers.add(e.title);
      }
    }

    final room = Matrix.of(context).client.getRoomById(roomId!)!;
    if (OkCancelResult.ok !=
        await showOkCancelAlertDialog(
          context: context,
          title:
              'You are about to invite ${uniqUsers.length} users and ${uniqGroups.length} groups (total: ${selection.length}) to room ${room.name}',
          okLabel: 'Invite',
          cancelLabel: L10n.of(context)!.cancel,
        )) {
      print('did not press ok');
      return;
    }
    final success = await showFutureLoadingDialog(
      context: context,
      future: () async {}, //room.invite(id),
    );
    if (success.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contacts have been invited'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errors during invite TODO'),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    loadAddressbook();
    treeController = TreeController<ABookEntry>(
      roots: abook,
      childrenProvider: (ABookEntry node) => node.children,
    );
  }

  @override
  void dispose() {
    treeController.dispose();
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TreeView<ABookEntry>(
      treeController: treeController,
      nodeBuilder: (BuildContext context, TreeEntry<ABookEntry> entry) {
        return AddressbookView(
          key: ValueKey(entry.node),
          entry: entry,
          onTap: () => {
            treeController.toggleExpansion(entry.node),
          },
          toggleEntry: () {
            toggleEntry(entry.node);
          },
          selection: selection,
          isSelected: () {
            return isSelected(entry.node);
          },
          displayAboveFirstEntry: (entry) {
            final c = treeController;
            final firstRoot = c.roots.first;
            // if it's the first root entry
            if (firstRoot == entry.node) {
              return true;
            }
            return false;
          },
          displayBelowLastEntry: (entry) {
            final c = treeController;
            final lastRoot = c.roots.last;
            final n = entry.node;
            // if it's the last root entry that is not expanded
            if (lastRoot == n && c.getExpansionState(lastRoot) == false) {
              return true;
            }
            if (c.getExpansionState(lastRoot) == true) {
              if (c.getExpansionState(lastRoot.children.last) == false &&
                  n == lastRoot.children.last) {
                return true;
              }
            }
            if (c.getExpansionState(lastRoot) == true) {
              if (c.getExpansionState(lastRoot.children.last) == true &&
                  n == lastRoot.children.last.children.last) {
                return true;
              }
            }
            return false;
          },
          invite: invite,
        );
      },
    );
  }
}
