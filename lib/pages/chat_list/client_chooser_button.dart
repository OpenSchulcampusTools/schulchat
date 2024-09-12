import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:matrix/matrix.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vrouter/vrouter.dart';

import 'package:fluffychat/pages/bootstrap/bootstrap_dialog.dart';
import 'package:fluffychat/widgets/avatar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import '../../config/app_config.dart';
import 'chat_list.dart';

class ClientChooserButton extends StatelessWidget {
  final ChatListController controller;

  const ClientChooserButton(this.controller, {Key? key}) : super(key: key);

  List<PopupMenuEntry<Object>> _bundleMenuItems(BuildContext context) {
    final matrix = Matrix.of(context);

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
      //schulchat-specific: show only displayname, seen in https://gitlab.com/famedly/fluffychat/-/blob/v1.11.0/lib/pages/chat_list/client_chooser_button.dart
      const PopupMenuItem(
        value: null,
        child: Divider(height: 1),
      ),
      PopupMenuItem(
        value: matrix.client,
        child: FutureBuilder<Profile?>(
          // analyzer does not understand this type cast for error
          // handling
          //
          // ignore: unnecessary_cast
          future: (matrix.client.fetchOwnProfile() as Future<Profile?>)
              .onError((e, s) => null),
          builder: (context, snapshot) => Row(
            children: [
              Avatar(
                mxContent: snapshot.data?.avatarUrl,
                name: snapshot.data?.displayName ?? "",
                size: 32,
                fontSize: 12,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  snapshot.data?.displayName ?? "",
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
      //schulchat-specific: add sign out button in client_chooser_button
      PopupMenuItem(
        value: SettingsAction.logout,
        child: Row(
          children: [
            const Icon(Icons.logout_outlined),
            const SizedBox(width: 18),
            Text(L10n.of(context)!.logout),
          ],
        ),
      ),
      if (!(matrix.client.getBackupQuestion()?.startsWith('q') ?? false))
        PopupMenuItem(
          value: SettingsAction.finishBackup,
          child: Row(
            children: [
              const Icon(Icons.warning_sharp),
              const SizedBox(width: 18),
              Text(L10n.of(context)!.finishChatBackup),
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
        case SettingsAction.finishBackup:
          await BootstrapDialog(
            client: Matrix.of(context).client,
          ).show(context);
          break;
        case SettingsAction
            .logout: //schulchat-specific: add sign out button in client_chooser_button
          if (await showOkCancelAlertDialog(
                useRootNavigator: false,
                context: context,
                title: L10n.of(context)!.areYouSureYouWantToLogout,
                message: L10n.of(context)!.noBackupWarning,
                //isDestructiveAction: noBackup,
                okLabel: L10n.of(context)!.logout,
                cancelLabel: L10n.of(context)!.cancel,
              ) ==
              OkCancelResult.cancel) {
            return;
          }
          await showFutureLoadingDialog(
            context: context,
            // future: () => matrix.client.logout(),
            future: () async {
              final matrix = Matrix.of(context);
              try {
                if (kIsWeb) {
                  launchUrl(Uri.parse(AppConfig.idpLogoutUrl));
                } else {
                  // Workaround using Webview
                  await FlutterWebAuth2.authenticate(
                    url: AppConfig.idpLogoutUrl,
                    callbackUrlScheme: 'https',
                  );
                }
                // retry logout?
              } catch (_) {}

              await matrix.client.logout();
            },
          );
          break;
      }
    }
  }
}

enum SettingsAction {
  newGroup,
  settings,
  archive,
  requireReadReceipt,
  showAddressbook,
  finishBackup,
  logout
}
