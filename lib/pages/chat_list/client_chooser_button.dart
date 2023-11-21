import 'package:flutter/material.dart';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';
import 'package:vrouter/vrouter.dart';

import 'package:fluffychat/widgets/avatar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import '../../config/app_config.dart';
import 'chat_list.dart';

class ClientChooserButton extends StatelessWidget {
  final ChatListController controller;

  const ClientChooserButton(this.controller, {Key? key}) : super(key: key);

  List<PopupMenuEntry<Object>> _bundleMenuItems(BuildContext context) {
    return <PopupMenuEntry<Object>>[
      PopupMenuItem(
        value: SettingsAction.newGroup,
        child: Row(
          children: [
            const Icon(Icons.group_add_outlined),
            const SizedBox(width: 18),
            Text(L10n.of(context)!.createNewGroup),
          ],
        ),
      ),
      PopupMenuItem(
        value: SettingsAction.archive,
        child: Row(
          children: [
            const Icon(Icons.archive_outlined),
            const SizedBox(width: 18),
            Text(L10n.of(context)!.archive),
          ],
        ),
      ),
      PopupMenuItem(
        value: SettingsAction.settings,
        child: Row(
          children: [
            const Icon(Icons.settings_outlined),
            const SizedBox(width: 18),
            Text(L10n.of(context)!.settings),
          ],
        ),
      ),
      PopupMenuItem(
        value: SettingsAction.requireReadReceipt,
        child: Row(
          children: [
            const Icon(Icons.mark_chat_read_outlined),
            const SizedBox(width: 18),
            Text(L10n.of(context)!.readReceipts),
          ],
        ),
      ),
      PopupMenuItem(
        value: SettingsAction.showAddressbook,
        child: Row(
          children: [
            const Icon(Icons.contacts),
            const SizedBox(width: 18),
            Text(L10n.of(context)!.addressbook),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final matrix = Matrix.of(context);

    int clientCount = 0;
    matrix.accountBundles.forEach((key, value) => clientCount += value.length);
    return FutureBuilder<Profile>(
      future: matrix.client.fetchOwnProfile(),
      builder: (context, snapshot) => Stack(
        alignment: Alignment.center,
        children: [
          PopupMenuButton<Object>(
            onSelected: (o) => _clientSelected(o, context),
            itemBuilder: _bundleMenuItems,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6, bottom: 4),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(99),
                    child: Avatar(
                      mxContent: snapshot.data?.avatarUrl,
                      name: snapshot.data?.displayName ??
                          matrix.client.userID!.localpart,
                      size: 28,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (controller.hasToGiveReadReceipt)
                  const Positioned(
                    bottom: 0,
                    right: 0,
                    child: Icon(
                      Icons.mark_chat_read,
                      color: AppConfig.primaryColor,
                      size: 16,
                    ),
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _clientSelected(
    Object object,
    BuildContext context,
  ) async {
    if (object is Client) {
      controller.setActiveClient(object);
    } else if (object is String) {
      controller.setActiveBundle(object);
    } else if (object is SettingsAction) {
      switch (object) {
        case SettingsAction.addAccount:
          final consent = await showOkCancelAlertDialog(
            context: context,
            title: L10n.of(context)!.addAccount,
            message: L10n.of(context)!.enableMultiAccounts,
            okLabel: L10n.of(context)!.next,
            cancelLabel: L10n.of(context)!.cancel,
          );
          if (consent != OkCancelResult.ok) return;
          VRouter.of(context).to('/settings/addaccount');
          break;
        case SettingsAction.newGroup:
          VRouter.of(context).to('/newgroup');
          break;
        case SettingsAction.settings:
          VRouter.of(context).to('/settings');
          break;
        case SettingsAction.archive:
          VRouter.of(context).to('/archive');
          break;
        case SettingsAction.requireReadReceipt:
          VRouter.of(context).to('/readreceipts');
          break;
        case SettingsAction.showAddressbook:
          VRouter.of(context).to('/addressbook');
          break;
      }
    }
  }
}

enum SettingsAction {
  addAccount,
  newGroup,
  settings,
  archive,
  requireReadReceipt,
  showAddressbook
}
