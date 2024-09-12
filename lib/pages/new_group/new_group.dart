import 'package:flutter/material.dart';

import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:matrix/matrix.dart' as sdk;
import 'package:vrouter/vrouter.dart';

import 'package:fluffychat/pages/new_group/new_group_view.dart';
import 'package:fluffychat/widgets/matrix.dart';

class NewGroup extends StatefulWidget {
  const NewGroup({Key? key}) : super(key: key);

  @override
  NewGroupController createState() => NewGroupController();
}

class NewGroupController extends State<NewGroup> {
  TextEditingController controller = TextEditingController();
  bool publicGroup = false;
  bool readOnly = false;

  void setPublicGroup(bool b) => setState(() => publicGroup = b);

  void setReadOnly(bool b) => setState(() => readOnly = b);

  void submitAction([_]) async {
    final client = Matrix.of(context).client;
    final roomID = await showFutureLoadingDialog(
      context: context,
      future: () async {
        final roomId = await client.createGroupChat(
          enableEncryption: true,
          visibility: sdk.Visibility.private,
          preset: sdk.CreateRoomPreset.privateChat,
          powerLevelContentOverride: {
            'invite': 50,
            if (readOnly) ...{'users_default': -1},
            'events': {
              "m.room.name": 50,
              "m.room.power_levels": 100,
              "m.room.history_visibility": 100,
              "m.room.canonical_alias": 50,
              "m.room.avatar": 50,
              "m.room.tombstone": 100,
              "m.room.server_acl": 100,
              "m.room.encryption": 100,
              'edu.matrix.klassenfunk.read_receipt': -2,
            },
          },
          /* #schulChatSpecific
          visibility:
              publicGroup ? sdk.Visibility.public : sdk.Visibility.private,
          preset: publicGroupx
              ? sdk.CreateRoomPreset.publicChatx
              : sdk.CreateRoomPreset.privateChat,
           */
          groupName: controller.text.isNotEmpty ? controller.text : null,
        );

        return roomId;
      },
    );
    if (roomID.error == null) {
      VRouter.of(context).toSegments(['rooms', roomID.result!, 'addressbook']);
    }
  }

  @override
  Widget build(BuildContext context) => NewGroupView(this);
}
