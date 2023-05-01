import 'dart:core';

import 'package:flutter/material.dart';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:matrix/matrix.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

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
    this.orgName,
    this.longName,
    this.kind,
    this.isSchool = false,
    this.active = false,
    this.scgroupUsersActive = const <String>[],
    this.scgroupUsersInactive = const <String>[],
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
  // all entries (except meta entries like Teachers, Students, etc) have a associated school
  final String? orgName;
  // all entries except meta entries and sc groups
  final String? longName;
  // TODO enum of teacher,student,parents,admins,sc-group
  final String? kind;
  // in case it is an category entry for a school
  final bool isSchool;
  // if IDM user has already signed up in synapse at least once
  final bool active;
  // active users in this group
  final List<String>? scgroupUsersActive;
  // inactive users in this group
  final List<String>? scgroupUsersInactive;
}

class AddressbookController extends State<AddressbookPage> {
  final AutoScrollController scrollController = AutoScrollController();

  final TextEditingController searchController = TextEditingController();
  List<ABookEntry> searchResults = [];
  String _lastSearchTerm = "";
  String _searchTerm = "";

  var abook = <ABookEntry>[];
  // wrap async abook loading, because initState cannot be async
  void loadAddressbook() async {
    abook = await buildAddressbook();
    setState(() {
      treeController.roots = abook;
      treeController.rebuild();
    });
  }

  // getter for nodes selected by an user
  Set<ABookEntry> get selection => selectedNodes;

  // true, if a given node has been selected
  // false, otherwise
  bool isSelected(ABookEntry node) {
    return selection.contains(node);
  }

  // holds all selected nodes
  // if a node has children, all childs are implicitly selected
  final Set<ABookEntry> selectedNodes = {};

  // [state] true, recursively add nodes to selection
  // [state] false, recursively remove nodes from selection
  void toggleRecursive(node, [state = true]) {
    Logs().d(
      'called recursive toggle for ${node.title}; active: ${node.active} category: ${node.category} group: ${node.kind}',
    );
    if (node.active || node.category || node.kind == 'group') {
      (state == true) ? selection.add(node) : selection.remove(node);
      if (node.children.isNotEmpty) {
        node.children.forEach((ABookEntry c) {
          toggleRecursive(c, state);
        });
      }
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

  /*
  // Removes a node and it's children from the abook, so
  // search results and the tree view don't show them anymore
  // TODO: if deactivated, call buildAddressbook again
  void toggleSchool(node, [activate = false]) {
    print('toggleSchool called with activate $activate');
    // removes or adds a school from search results and addressbook view

    // check if it is a school
    if (node.category && node.isSchool) {
      if (activate) {
        print('remove ${node.title}\'s children and node from list');
        // FIXME instead of removing the selection, remove the node from abook
        // if we remove it now, the radio button entry disappears, too so we cannot add it again
        toggleRecursive(node, true);
        //treeController.roots.remove(node);
        setState(() {});
      }
    }
  }*/

  List<String> listOfSchools = [];
  Future<Map<String, dynamic>> fetchAddressbook() async {
    final abookJson = await Matrix.of(context).client.request(
          RequestType.GET,
          '/client/unstable/fairkom.fairmessenger.addressbook/addressbook',
        );
    return abookJson;
  }

  Future<List<ABookEntry>> buildAddressbook() async {
    final abookEntries = <ABookEntry>[];
    final abookJson = await fetchAddressbook();
    for (final school in abookJson.keys) {
      // not a school, but contains a list of all users returned with the address book
      if (school == 'users') continue;

      final schoolName = abookJson[school]['name'];
      //final schoolName = await Matrix.of(context).client.request(RequestType.GET, '/../idm/school/${school}');
      final abookSchool = ABookEntry(
        title: schoolName,
        children: [],
        category: true,
        isSchool: true,
      );
      listOfSchools.add(abookSchool.title);
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
      if (abookJson[school]['teachers'] != null &&
          abookJson[school]['teachers'].isNotEmpty) {
        abookSchool.children.add(abookTeacher);
        abookJson[school]['teachers'].forEach((teacher) {
          abookTeacher.children.add(
            ABookEntry(
              title: teacher,
              info: '${L10n.of(context)!.contactsInfoTeacher} $schoolName',
              orgName: schoolName,
              longName: abookJson['users'][teacher].first,
              kind: 'teacher', //TODO
              active: abookJson['users'][teacher].last == 'active',
            ),
          );
        });
      }
      if (abookJson[school]['scgroups'] != null &&
          abookJson[school]['scgroups'].isNotEmpty) {
        abookSchool.children.add(abookSCGroups);
        abookJson[school]['scgroups'].forEach((id, groupData) {
          final name = groupData.first;
          final users = groupData.last;
          final List<String> activeUsers = [];
          final List<String> inactiveUsers = [];
          users.forEach((uid) {
            if (abookJson['users'][uid].last == 'active') {
              activeUsers.add(uid);
            } else {
              inactiveUsers.add(uid);
            }
          });
          abookSCGroups.children.add(
            ABookEntry(
              title: name,
              id: id,
              info: '${L10n.of(context)!.contactsInfoGroup} $schoolName',
              orgName: schoolName,
              kind: 'group', //TODO
              scgroupUsersActive: activeUsers,
              scgroupUsersInactive: inactiveUsers,
            ),
          );
        });
      }
      if (abookJson[school]['students'] != null &&
          abookJson[school]['students'].isNotEmpty) {
        abookSchool.children.add(abookStudents);
        abookJson[school]['students'].forEach((student) {
          abookStudents.children.add(
            ABookEntry(
              title: student,
              info: '${L10n.of(context)!.contactsInfoStudent} $schoolName',
              orgName: schoolName,
              longName: abookJson['users'][student].first,
              kind: 'student', //TODO
              active: abookJson['users'][student].last == 'active',
            ),
          );
        });
      }
      if (abookJson[school]['parents'] != null &&
          abookJson[school]['parents'].isNotEmpty) {
        abookSchool.children.add(abookParents);
        abookJson[school]['parents'].forEach((parent) {
          abookParents.children.add(
            ABookEntry(
              title: parent,
              info: '${L10n.of(context)!.contactsInfoParent} $schoolName',
              orgName: schoolName,
              longName: abookJson['users'][parent].first,
              kind: 'parent', //TODO
              active: abookJson['users'][parent].last == 'active',
            ),
          );
        });
      }
      if (abookJson[school]['admins'] != null &&
          abookJson[school]['admins'].isNotEmpty) {
        abookSchool.children.add(abookAdmins);
        abookJson[school]['admins'].forEach((admin) {
          abookAdmins.children.add(
            ABookEntry(
              title: admin,
              info: '${L10n.of(context)!.contactsInfoAdmin} $schoolName',
              orgName: schoolName,
              longName: abookJson['users'][admin].first,
              kind: 'admin', //TODO
              active: abookJson['users'][admin].last == 'active',
            ),
          );
        });
      }
      abookEntries.add(abookSchool);
    }
    Logs().d('List of schools: $listOfSchools');
    return abookEntries;
  }

  late final TreeController<ABookEntry> treeController;

  // gets a list of user and group ids and tries to invite them
  // returns a Set of success/failure per id
  void invite(invitees, roomId) async {
    // selection can contain the same user multiple times
    final Set uniqUsers = {};
    final Set uniqGroups = {};
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
      Logs().v('Did not press ok');
      return;
    }
    final success = await showFutureLoadingDialog(
      context: context,
      future: () async {}, //room.invite(id),
    );
    if (success.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contacts have been invited.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error during invitation'),
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

  void onTap(entry) {
    treeController.toggleExpansion(entry.node);
  }

  void search() {
    _searchTerm = searchController.text;

    // start search only if a new search term was entered
    if (_searchTerm != _lastSearchTerm) {
      _lastSearchTerm = _searchTerm;
      searchResults.clear();

      setState(() {
        showSearchResults;
      });

      if (_searchTerm.isNotEmpty) {
        _recursiveSearchTree(abook);
      }
    }
  }

  void _recursiveSearchTree(aBookList) {
    aBookList.forEach((e) {
      // the address book always starts with category entries like school or 'All teachers'
      // we don't want to match those entries
      if (!e.category) {
        if (e.longName != null &&
                e.longName!.toLowerCase().contains(_searchTerm.toLowerCase()) ||
            e.title.toLowerCase().contains(_searchTerm.toLowerCase())) {
          searchResults.add(e);
          setState(() {
            searchResults;
          });
        }
      } else {
        if (e.children.isNotEmpty) {
          _recursiveSearchTree(e.children);
        }
      }
    });
  }

  bool get showSearchResults => searchController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return AddressbookView(this);
  }
}
