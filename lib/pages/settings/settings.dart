import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:matrix/matrix.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fluffychat/pages/bootstrap/bootstrap_dialog.dart';
import '../../config/app_config.dart';
import '../../widgets/matrix.dart';
import 'settings_view.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  SettingsController createState() => SettingsController();
}

class SettingsController extends State<Settings> {
  Future<Profile>? profileFuture;
  bool profileUpdated = false;

  void logoutAction() async {
    const noBackup = false; //showChatBackupBanner == true;
    if (await showOkCancelAlertDialog(
          useRootNavigator: false,
          context: context,
          title: L10n.of(context)!.areYouSureYouWantToLogout,
          message: L10n.of(context)!.noBackupWarning,
          isDestructiveAction: noBackup,
          okLabel: L10n.of(context)!.logout,
          cancelLabel: L10n.of(context)!.cancel,
        ) ==
        OkCancelResult.cancel) {
      return;
    }
    await showFutureLoadingDialog(
      context: context,
      // future: () => matrix.client.logout(),
      future: () => logoutWrapper(context),
    );
  }

  Future<void> logoutWrapper(pContext) async {
    final matrix = Matrix.of(pContext);
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
  }

  @override
  void initState() {
    //WidgetsBinding.instance.addPostFrameCallback((_) => checkBootstrap());

    super.initState();
  }

  /*
  void checkBootstrap() async {
    final client = Matrix.of(context).client;
    if (!client.encryptionEnabled) return;
    await client.accountDataLoading;
    await client.userDeviceKeysLoading;
    if (client.prevBatch == null) {
      await client.onSync.stream.first;
    }
    final crossSigning =
        await client.encryption?.crossSigning.isCached() ?? false;
    final needsBootstrap =
        await client.encryption?.keyManager.isCached() == false ||
            client.encryption?.crossSigning.enabled == false ||
            crossSigning == false;
    // not verified
    final isUnknownSession = client.isUnknownSession;
    setState(() {
      showChatBackupBanner = needsBootstrap || isUnknownSession;
    });
  }
  */
  void resetBackupDialog(BuildContext context) async {
    await BootstrapDialog(
      client: Matrix.of(context).client,
      wipe: true,
    ).show(context);
  }

  bool? crossSigningCached;
  bool? showChatBackupBanner;

  /*
  void firstRunBootstrapAction([_]) async {
    if (showChatBackupBanner != true) {
      showOkAlertDialog(
        context: context,
        title: L10n.of(context)!.chatBackup,
        message: L10n.of(context)!.onlineKeyBackupEnabled,
        okLabel: L10n.of(context)!.close,
      );
      return;
    }
    await BootstrapDialog(
      client: Matrix.of(context).client,
    ).show(context);
    checkBootstrap();
  }
  */

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;
    profileFuture ??= client.getProfileFromUserId(
      client.userID!,
      cache: !profileUpdated,
      getFromRooms: !profileUpdated,
    );
    return SettingsView(this);
  }
}

enum AvatarAction { camera, file, remove }
