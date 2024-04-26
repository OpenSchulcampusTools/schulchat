import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';

import '../../utils/adaptive_bottom_sheet.dart';
import '../../widgets/matrix.dart';
import 'chat_details.dart';

class SCGroupListItem extends StatefulWidget {
  final String group;
  final ChatDetailsController controller;

  const SCGroupListItem(this.group, this.controller, {Key? key})
      : super(key: key);

  @override
  SCGroupListItemState createState() => SCGroupListItemState();
}

class SCGroupListItemState extends State<SCGroupListItem> {
  bool showUserList = false;

  Future<String> get getGroupName async {
    return await widget.controller
        .getNameOfSCGroup(extractGroupId(widget.group));
  }

  Future<List<dynamic>> get getMembersOfSCGroup async {
    return await widget.controller
        .getMemberNamesOfSCGroup(extractGroupId(widget.group));
  }

  String extractGroupId(String group) {
    return group.split(':')[0].split('--')[1];
  }

  //TODO: use Identifer
  String extractSchoolIdentifier(String group) {
    return group.split(':')[0].split('--')[0].split('#')[1];
  }

  void _showMembersBottomSheet(String groupName, int ownPowerLevel) {
    showAdaptiveBottomSheet(
      context: context,
      builder: (context) {
        return FutureBuilder<List<dynamic>>(
          future: getMembersOfSCGroup,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Fehler: ${snapshot.error}');
            } else {
              final List<dynamic> membersOfAGroup = snapshot.data ?? [];

              return Scaffold(
                appBar: AppBar(
                  leading: CloseButton(
                    onPressed: Navigator.of(context, rootNavigator: false).pop,
                  ),
                  title: Text(groupName),
                  actions: [
                    if (ownPowerLevel >= 100)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              widget.controller.removeGroupFromRoom(
                            extractGroupId(widget.group),
                          ),
                          icon: const Icon(Icons.group),
                          label: Text(L10n.of(context)!.removeGroupFromRoom),
                        ),
                      ),
                  ],
                ),
                body: ListView(
                  children: [
                    const SizedBox(height: 8.0),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: membersOfAGroup.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(membersOfAGroup[index]),
                        );
                      },
                    ),
                    const SizedBox(height: 16.0),
                  ],
                ),
              );
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final room =
        Matrix.of(context).client.getRoomById(widget.controller.roomId!);
    final ownPowerLevel = room?.ownPowerLevel;

    return FutureBuilder<String>(
      future: getGroupName,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          final groupName = snapshot.data ?? "";
          return ListTile(
            title: Text(groupName),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              child: const Icon(Icons.group),
            ),
            onTap: () => _showMembersBottomSheet(groupName, ownPowerLevel!),
          );
        }
      },
    );
  }
}
