import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import 'package:fluffychat/pages/qrscan/qrscan_view.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/matrix.dart';

class QRScan extends StatefulWidget {
  const QRScan({Key? key}) : super(key: key);

  @override
  QRScanController createState() => QRScanController();
}

class QRScanController extends State<QRScan> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;
  bool isCurrentlySendingAuthorizationCode = false;

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) => QRScanView(this);

  void onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });

    controller.scannedDataStream.listen((scanData) {
      if (scanData.code == null) {
        return;
      }

      final authorizationCode =
          jsonDecode(scanData.code!)["authorization_code"];

      if (authorizationCode == null) {
        return;
      }

      if (isCurrentlySendingAuthorizationCode == false) {
        sendAuthorizationCode(authorizationCode);
      }
    });
  }

  Future<void> sendAuthorizationCode(String authorizationCode) async {
    isCurrentlySendingAuthorizationCode = true;

    try {
      final response = await http.get(Uri.parse(
          '${Matrix.of(context).getLoginClient().homeserver?.toString()}/_synapse/client/oidc/callbacksc?code=${authorizationCode}'));

      if (response.statusCode == 200) {
        final htmlDoc = String.fromCharCodes(response.bodyBytes);
        RegExp regExp = RegExp(r'(?<=loginToken=)[\w-]+');
        Match? match = regExp.firstMatch(htmlDoc);
        String? token = match?.group(0);

        if (token?.isEmpty ?? true) return;

        await showFutureLoadingDialog(
          context: context,
          future: () => Matrix.of(context).getLoginClient().login(
                LoginType.mLoginToken,
                token: token,
                initialDeviceDisplayName: PlatformInfos.clientName,
              ),
        );
      } else {
        print('Failed to send authorization code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending authorization code: $e');
    }

    isCurrentlySendingAuthorizationCode = false;
  }

  void onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
