import 'dart:core';

import 'package:flutter/material.dart';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:matrix/matrix.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

import 'package:fluffychat/utils/invite_exception.dart';
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
    required this.orgName,
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
  // all entries have an associated school
  final String orgName;
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

// represents teacher, parent, admin and student, ie all user roles
class FlatUser {
  const FlatUser({
    required this.username,
    required this.longName,
    required this.active,
  });

  final String username;
  final String longName;
  final bool active;
}

class AddressbookController extends State<AddressbookPage> {
  final AutoScrollController scrollController = AutoScrollController();

  // this is only used for deselecting single users of a SC group
  // Contains only those users that are part of a SC group
  List<FlatUser> usersInSCGroups = [];

  // Contains all users
  // Multiple entries are possible when an user has multiple roles
  Map<String, List<ABookEntry>> allUsers = {};

  var abook = <ABookEntry>[];

  // getter for nodes selected by an user
  Set<ABookEntry> get selection => selectedNodes;

  // true, if a given node has been selected
  // false, otherwise
  bool isSelected(ABookEntry node) {
    return selection.contains(node);
  }

  // holds all selected nodes
  // if a node has children, all childs are explicitly selected
  final Set<ABookEntry> selectedNodes = {};

  // [state] true, recursively add nodes to selection
  // [state] false, recursively remove nodes from selection
  void toggleRecursive(node, [state = true]) {
    //Logs().d(
    //  'called recursive toggle to state $state for ${node.title}; active: ${node.active} category: ${node.category} group: ${node.kind}, school: ${node.orgName}',
    //);
    //if (node.active || node.category || node.kind == 'group') {
    (state == true) ? selection.add(node) : selection.remove(node);
    if (node.children.isNotEmpty) {
      node.children.forEach((ABookEntry c) {
        toggleRecursive(c, state);
      });
    }
    //}
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

  bool syncWarningShown = false;
  // Mainly for deselecting users that are part of a group but should not be part
  // of the newly created room.
  //
  // If a group member is deselected, we not longer sync the resulting memberships with IDM.
  // That's why we add all members, except the deselected one, and remove the sc group from the list
  // of selected contacts.
  Future<void> removeGroupMember(group, groupMemberName) async {
    if (syncWarningShown) {
      await _removeGroupMember(group, groupMemberName);
    } else {
      if (OkCancelResult.ok !=
          await showOkCancelAlertDialog(
            context: context,
            title: L10n.of(context)!.groupMemberRemoveTitle(group.title),
            okLabel: L10n.of(context)!.groupMemberRemoveLabel,
            cancelLabel: L10n.of(context)!.cancel,
          )) {
        Logs().v('Did not press ok');
        return;
      }
      final success = await showFutureLoadingDialog(
        context: context,
        future: () async {
          await _removeGroupMember(group, groupMemberName);
        },
      );
      if (success.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L10n.of(context)!.inviteErrorHappened),
          ),
        );
      }
    }
  }

  Future<void> _removeGroupMember(group, groupMemberName) async {
    syncWarningShown = true;
    final school = group.orgName;

    // add all members of the group
    final toBeAdded = [
      ...group.scgroupUsersActive,
      ...group.scgroupUsersInactive
    ];
    // this is the user that is actually removed from the selection
    toBeAdded.remove(groupMemberName);

    for (final userEntry in allUsers[school]!) {
      if (toBeAdded.contains(userEntry.title)) {
        selection.add(userEntry);
      }
    }

    // remove the group
    // no-op in case it is not the first user that is removed from the selection
    toggleRecursive(group, false);

    // prevent the user from being added again
    if (!deselectedUserEntries.contains(groupMemberName)) {
      deselectedUserEntries.add(groupMemberName);
    }

    setState(() {
      treeController.rebuild();
    });
  }

  List<String> deselectedUserEntries = [];

  bool invitesFromMultipleSchools() {
    bool multipleSchools = false;
    final String firstSelectedSchool;

    if (selection.isEmpty) {
      return false;
    } else {
      firstSelectedSchool = selection.first.orgName;
    }

    for (final n in selection) {
      if (n.orgName != firstSelectedSchool) {
        multipleSchools = true;
        break;
      }
    }
    return multipleSchools;
  }

  // what is the school of the invitees?
  // returns null if there are no invitees
  String? selectedSchool() {
    if (selection.isEmpty) return null;

    return selection.first.orgName;
  }

  List<ABookEntry> listOfSchools = [];

  // wrap async abook loading, because initState cannot be async
  void loadAddressbook() async {
    abook = await buildAddressbook();
    setState(() {
      treeController.roots = abook;
      treeController.rebuild();
    });
  }

  Future<List<ABookEntry>> buildAddressbook() async {
    final abookEntries = <ABookEntry>[];
    final abookJson = await Matrix.of(context).client.fetchAddressbook();
    if (abookJson.keys.isNotEmpty) {
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
          orgName: school,
        );
        listOfSchools.add(abookSchool);
        final abookTeacher = ABookEntry(
          title: L10n.of(context)!.abookTitleTeachers,
          children: [],
          category: true,
          orgName: school,
        );
        final abookSCGroups = ABookEntry(
          title: L10n.of(context)!.abookTitleSCGroups,
          children: [],
          category: true,
          orgName: school,
        );
        final abookStudents = ABookEntry(
          title: L10n.of(context)!.abookTitleStudents,
          children: [],
          category: true,
          orgName: school,
        );
        final abookParents = ABookEntry(
          title: L10n.of(context)!.abookTitleParents,
          children: [],
          category: true,
          orgName: school,
        );
        final abookAdmins = ABookEntry(
          title: L10n.of(context)!.abookTitleAdmins,
          children: [],
          category: true,
          orgName: school,
        );
        allUsers[school] = [];
        if (abookJson[school]['teachers'] != null &&
            abookJson[school]['teachers'].isNotEmpty) {
          abookSchool.children.add(abookTeacher);
          abookJson[school]['teachers'].forEach((teacher) {
            final entry = ABookEntry(
              title: teacher,
              info: '${L10n.of(context)!.contactsInfoTeacher} $schoolName',
              orgName: school,
              longName: abookJson['users'][teacher].first,
              kind: 'teacher', //TODO
              active: abookJson['users'][teacher].last == 'active',
            );
            abookTeacher.children.add(
              entry,
            );
            allUsers[school]!.add(entry);
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
                //FIXME multiple entries of same users!
                usersInSCGroups.add(
                  FlatUser(
                    username: uid,
                    longName: abookJson['users'][uid].first,
                    active: true,
                  ),
                );
              } else {
                inactiveUsers.add(uid);
                //FIXME multiple entries of same users!
                usersInSCGroups.add(
                  FlatUser(
                    username: uid,
                    longName: abookJson['users'][uid].first,
                    active: false,
                  ),
                );
              }
            });
            abookSCGroups.children.add(
              ABookEntry(
                title: name,
                id: id,
                info: '${L10n.of(context)!.contactsInfoGroup} $schoolName',
                orgName: school,
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
            final entry = ABookEntry(
              title: student,
              info: '${L10n.of(context)!.contactsInfoStudent} $schoolName',
              orgName: school,
              longName: abookJson['users'][student].first,
              kind: 'student', //TODO
              active: abookJson['users'][student].last == 'active',
            );
            abookStudents.children.add(
              entry,
            );
            allUsers[school]!.add(entry);
          });
        }
        if (abookJson[school]['parents'] != null &&
            abookJson[school]['parents'].isNotEmpty) {
          abookSchool.children.add(abookParents);
          abookJson[school]['parents'].forEach((parent) {
            final entry = ABookEntry(
              title: parent,
              info: '${L10n.of(context)!.contactsInfoParent} $schoolName',
              orgName: school,
              longName: abookJson['users'][parent].first,
              kind: 'parent', //TODO
              active: abookJson['users'][parent].last == 'active',
            );
            abookParents.children.add(
              entry,
            );
            allUsers[school]!.add(entry);
          });
        }
        if (abookJson[school]['admins'] != null &&
            abookJson[school]['admins'].isNotEmpty) {
          abookSchool.children.add(abookAdmins);
          abookJson[school]['admins'].forEach((admin) {
            final entry = ABookEntry(
              title: admin,
              info: '${L10n.of(context)!.contactsInfoAdmin} $schoolName',
              orgName: school,
              longName: abookJson['users'][admin].first,
              kind: 'admin', //TODO
              active: abookJson['users'][admin].last == 'active',
            );
            abookAdmins.children.add(
              entry,
            );
            allUsers[school]!.add(entry);
          });
        }
        abookEntries.add(abookSchool);
      }
      Logs()
          .d('List of schools: ${listOfSchools.map((s) => s.title).toList()}');
    }
    return abookEntries;
  }

  late final TreeController<ABookEntry> treeController;

  // receives a list of user and group ids and tries to invite them
  // returns a Set of success/failure per id
  void invite(invitees, String roomId) async {
    // selection can contain the same user multiple times
    final Set uniqUsers = {};
    final List<String> uniqGroups = [];
    final hs = Matrix.of(context).client.homeserver?.host;

    final orgName = selectedSchool();

    for (final e in selection) {
      if (e.id != null) {
        uniqGroups.add('#${e.orgName}--${e.id}:$hs');
      } else {
        uniqUsers.add('@${e.title}:$hs');
      }
    }

    final room = Matrix.of(context).client.getRoomById(roomId)!;
    if (OkCancelResult.ok !=
        await showOkCancelAlertDialog(
          context: context,
          title: L10n.of(context)!.inviteTitleMessage(
            uniqUsers.length,
            uniqGroups.length,
            selection.length,
            room.name,
          ),
          okLabel: L10n.of(context)!.inviteOKLabel,
          cancelLabel: L10n.of(context)!.cancel,
        )) {
      Logs().v('Did not press ok');
      return;
    }
    final success = await showFutureLoadingDialog(
      context: context,
      future: () async {
        final List<String> errors = [];
        for (final u in uniqUsers) {
          try {
            Logs().v('about to invite $u');
            await room.invite(u);
          } on MatrixException catch (e) {
            errors.add(e.errorMessage);
          }
        }
        if (uniqGroups.isNotEmpty) {
          Logs().v('about to invite groups $uniqGroups');
          room.setRestrictedJoinRules(uniqGroups);
        }
        if (orgName != null) {
          room.setSchoolId(orgName);
        }

        // we collected all errors above, now throw an exception
        if (errors.isNotEmpty) {
          throw InviteException(errors.join('\n'));
        }
      },
    );
    if (success.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.of(context)!.invitedContactsDone),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.of(context)!.inviteErrorHappened),
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

  final TextEditingController searchController = TextEditingController();
  List<ABookEntry> searchResults = [];
  String _lastSearchTerm = "";
  String _searchTerm = "";

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
