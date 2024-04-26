import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
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

  void showErrorDialog(
    BuildContext context,
    String authorizationCode,
    String error,
  ) {
    final String scanError = L10n.of(context)!.scanError;
    final String scanErrorExplanation =
        L10n.of(context)!.scanErrorExplanation(error);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(scanError),
          content: Text(scanErrorExplanation),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                isCurrentlySendingAuthorizationCode = false;
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> finishLogin(String? token) async {
    if (token == null || token.isEmpty) {
      final tokenEmptyMessage = L10n.of(context)!.scanErrorToken;
      throw Exception(tokenEmptyMessage);
    }

    await showFutureLoadingDialog(
      context: context,
      future: () => Matrix.of(context).getLoginClient().login(
            LoginType.mLoginToken,
            token: token,
            initialDeviceDisplayName: PlatformInfos.clientName,
          ),
    );
    return;
  }

  Future<void> sendAuthorizationCode(String authorizationCode) async {
    isCurrentlySendingAuthorizationCode = true;

    try {
      final http.Request req = http.Request(
        'Get',
        Uri.parse(
          '${Matrix.of(context).getLoginClient().homeserver?.toString()}/_synapse/client/oidc/callbacksc?code=$authorizationCode',
        ),
      );
      req.followRedirects = false;
      final http.Client httpClient = http.Client();
      final http.StreamedResponse response = await httpClient.send(req);

      // if the response is a 302 redirect and contains a location header
      if (response.statusCode == 302 && response.headers['location'] != null) {
        final Uri redirectUri = Uri.parse(response.headers['location']!);
        final String? token = redirectUri.queryParameters['loginToken'];
        await finishLogin(token);
      } else if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        final RegExp regExp = RegExp(r'(?<=loginToken=)[\w-]+');
        final Match? match = regExp.firstMatch(body);
        final String? token = match?.group(0);
        await finishLogin(token);
      }
      if (response.statusCode == 400) {
        final statusCodeMessage = L10n.of(context)!.scanErrorAgain;
        throw Exception(statusCodeMessage);
      } else {
        final statusCode = response.statusCode;
        throw Exception(' $statusCode');
      }
    } catch (e) {
      showErrorDialog(context, authorizationCode, e.toString());
      Logs().e('Error sending authorization code: $e');
    }
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
