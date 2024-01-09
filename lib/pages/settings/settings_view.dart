import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:vrouter/vrouter.dart';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'settings.dart';

class SettingsView extends StatelessWidget {
  final SettingsController controller;

  const SettingsView(this.controller, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final showChatBackupBanner = controller.showChatBackupBanner;
    return Scaffold(
      appBar: AppBar(
        leading: CloseButton(
          onPressed: VRouter.of(context).pop,
        ),
        title: Text(L10n.of(context)!.settings),
        actions: [
          TextButton.icon(
            onPressed: controller.logoutAction,
            label: Text(L10n.of(context)!.logout),
            icon: const Icon(Icons.logout_outlined),
          ),
        ],
      ),
      body: ListTileTheme(
        iconColor: Theme.of(context).colorScheme.onBackground,
        child: ListView(
          key: const Key('SettingsListViewContent'),
          children: <Widget>[
            const Divider(thickness: 1),
            if (showChatBackupBanner == null)
              ListTile(
                leading: const Icon(Icons.backup_outlined),
                title: Text(L10n.of(context)!.chatBackup),
                trailing: const CircularProgressIndicator.adaptive(),
              )
            else
              SwitchListTile.adaptive(
                controlAffinity: ListTileControlAffinity.trailing,
                value: controller.showChatBackupBanner == false,
                secondary: const Icon(Icons.backup_outlined),
                title: Text(L10n.of(context)!.chatBackup),
                onChanged: controller.firstRunBootstrapAction,
              ),
            const Divider(thickness: 1),
            ListTile(
              leading: const Icon(Icons.format_paint_outlined),
              title: Text(L10n.of(context)!.changeTheme),
              onTap: () => VRouter.of(context).to('/settings/style'),
              trailing: const Icon(Icons.chevron_right_outlined),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: Text(L10n.of(context)!.notifications),
              onTap: () => VRouter.of(context).to('/settings/notifications'),
              trailing: const Icon(Icons.chevron_right_outlined),
            ),
            ListTile(
              leading: const Icon(Icons.devices_outlined),
              title: Text(L10n.of(context)!.devices),
              onTap: () => VRouter.of(context).to('/settings/devices'),
              trailing: const Icon(Icons.chevron_right_outlined),
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline_outlined),
              title: Text(L10n.of(context)!.chat),
              onTap: () => VRouter.of(context).to('/settings/chat'),
              trailing: const Icon(Icons.chevron_right_outlined),
            ),
            ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: Text(L10n.of(context)!.security),
              onTap: () => VRouter.of(context).to('/settings/security'),
              trailing: const Icon(Icons.chevron_right_outlined),
            ),
            const Divider(thickness: 1),
            ListTile(
              leading: const Icon(Icons.help_outline_outlined),
              title: Text(L10n.of(context)!.help),
              onTap: () => launchUrlString(AppConfig.supportUrl),
              trailing: const Icon(Icons.open_in_new_outlined),
            ),
            ListTile(
              leading: const Icon(Icons.shield_sharp),
              title: Text(L10n.of(context)!.privacy),
              onTap: () => launchUrlString(AppConfig.privacyUrl),
              trailing: const Icon(Icons.open_in_new_outlined),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: Text(L10n.of(context)!.about),
              onTap: () => PlatformInfos.showDialog(context),
              trailing: const Icon(Icons.chevron_right_outlined),
            ),
          ],
        ),
      ),
    );
  }
}
