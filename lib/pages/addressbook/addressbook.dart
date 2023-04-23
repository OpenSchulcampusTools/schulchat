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
import '../chat_search/chat_search.dart';
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
}

class AddressbookController extends State<AddressbookPage> {
  final TextEditingController searchController = TextEditingController();
  SearchState searchState = SearchState.noResult;
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
    (state == true) ? selection.add(node) : selection.remove(node);
    if (node.children.isNotEmpty) {
      node.children.forEach((ABookEntry c) {
        toggleRecursive(c, state);
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

  void toggleSchool(node) {
    // removes or adds a school from search results and addressbook view

    // check if it is a school
    if (node.category && node.isSchool) {
      print('should remove ${node.title} from list');
    }
  }

  List<ABookEntry> listOfSchools = [];
  Future<Map<String, dynamic>> fetchAddressbook() async {
    // temp HACK for showcase in case of integration1, set idm user to m.hannich
    final userId =
        (Matrix.of(context).client.userID!.localpart == 'integration1' ||
                Matrix.of(context).client.userID!.localpart == 'm.h')
            ? 'm.hannich'
            : Matrix.of(context).client.userID!.localpart;
    //const url = 'http://localhost:8085/u/m.hannich/addressbook';
    //final abookJson =
    //    json.decode(utf8.decode((await http.get(Uri.parse(url))).bodyBytes));
    final abookJson = await Matrix.of(context).client.request(RequestType.GET,
        '/../idm/u/BN7xs2BJeXH95gXAx6CII/${userId}/addressbook');
    return abookJson;
  }

  Future<List<ABookEntry>> buildAddressbook() async {
    final abookEntries = <ABookEntry>[];
    final abookJson = await fetchAddressbook();
    for (final school in abookJson.keys) {
      // this is a special key in the address book - not a school
      if (school == 'users') continue;

      final schoolName = abookJson[school]['name'];
      //final schoolName = await Matrix.of(context).client.request(RequestType.GET, '/../idm/school/${school}');
      final abookSchool = ABookEntry(
          title: schoolName, children: [], category: true, isSchool: true);
      listOfSchools.add(abookSchool);
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
              longName: abookJson['users'][teacher],
              kind: 'teacher', //TODO
            ),
          );
        });
      }
      if (abookJson[school]['scgroups'] != null &&
          abookJson[school]['scgroups'].isNotEmpty) {
        abookSchool.children.add(abookSCGroups);
        abookJson[school]['scgroups'].forEach((id, name) {
          abookSCGroups.children.add(
            ABookEntry(
              title: name,
              id: id,
              info: '${L10n.of(context)!.contactsInfoGroup} $schoolName',
              orgName: schoolName,
              kind: 'group', //TODO
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
              longName: abookJson['users'][student],
              kind: 'student', //TODO
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
              longName: abookJson['users'][parent],
              kind: 'parent', //TODO
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
              longName: abookJson['users'][admin],
              kind: 'admin', //TODO
            ),
          );
        });
      }
      abookEntries.add(abookSchool);
    }
    print('list of schools: ${listOfSchools}');
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
          content: const Text('Contacts have been invited.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: const Text('Error during invitation'),
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
        searchState = SearchState.noResult;
        showSearchResults;
      });

      if (_searchTerm.isNotEmpty) {
        setState(() {
          searchState = SearchState.searching;
        });

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
