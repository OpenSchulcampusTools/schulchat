import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:keyboard_shortcuts/keyboard_shortcuts.dart';
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
          ...List.generate(
            clientCount,
            (index) => KeyBoardShortcuts(
              keysToPress: _buildKeyboardShortcut(index + 1),
              helpLabel: L10n.of(context)!.switchToAccount(index + 1),
              onKeysPressed: () => _handleKeyboardShortcut(
                matrix,
                index,
                context,
              ),
              child: Container(),
            ),
          ),
          KeyBoardShortcuts(
            keysToPress: {
              LogicalKeyboardKey.controlLeft,
              LogicalKeyboardKey.tab
            },
            helpLabel: L10n.of(context)!.nextAccount,
            onKeysPressed: () => _nextAccount(matrix, context),
            child: Container(),
          ),
          KeyBoardShortcuts(
            keysToPress: {
              LogicalKeyboardKey.controlLeft,
              LogicalKeyboardKey.shiftLeft,
              LogicalKeyboardKey.tab
            },
            helpLabel: L10n.of(context)!.previousAccount,
            onKeysPressed: () => _previousAccount(matrix, context),
            child: Container(),
          ),
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

  Set<LogicalKeyboardKey>? _buildKeyboardShortcut(int index) {
    if (index > 0 && index < 10) {
      return {
        LogicalKeyboardKey.altLeft,
        LogicalKeyboardKey(0x00000000030 + index)
      };
    } else {
      return null;
    }
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

  void _handleKeyboardShortcut(
    MatrixState matrix,
    int index,
    BuildContext context,
  ) {
    final bundles = matrix.accountBundles.keys.toList()
      ..sort(
        (a, b) => a!.isValidMatrixId == b!.isValidMatrixId
            ? 0
            : a.isValidMatrixId && !b.isValidMatrixId
                ? -1
                : 1,
      );
    // beginning from end if negative
    if (index < 0) {
      int clientCount = 0;
      matrix.accountBundles
          .forEach((key, value) => clientCount += value.length);
      _handleKeyboardShortcut(matrix, clientCount, context);
    }
    for (final bundleName in bundles) {
      final bundle = matrix.accountBundles[bundleName];
      if (bundle != null) {
        if (index < bundle.length) {
          return _clientSelected(bundle[index]!, context);
        } else {
          index -= bundle.length;
        }
      }
    }
    // if index too high, restarting from 0
    _handleKeyboardShortcut(matrix, 0, context);
  }

  int? _shortcutIndexOfClient(MatrixState matrix, Client client) {
    int index = 0;

    final bundles = matrix.accountBundles.keys.toList()
      ..sort(
        (a, b) => a!.isValidMatrixId == b!.isValidMatrixId
            ? 0
            : a.isValidMatrixId && !b.isValidMatrixId
                ? -1
                : 1,
      );
    for (final bundleName in bundles) {
      final bundle = matrix.accountBundles[bundleName];
      if (bundle == null) return null;
      if (bundle.contains(client)) {
        return index + bundle.indexOf(client);
      } else {
        index += bundle.length;
      }
    }
    return null;
  }

  void _nextAccount(MatrixState matrix, BuildContext context) {
    final client = matrix.client;
    final lastIndex = _shortcutIndexOfClient(matrix, client);
    _handleKeyboardShortcut(matrix, lastIndex! + 1, context);
  }

  void _previousAccount(MatrixState matrix, BuildContext context) {
    final client = matrix.client;
    final lastIndex = _shortcutIndexOfClient(matrix, client);
    _handleKeyboardShortcut(matrix, lastIndex! - 1, context);
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
