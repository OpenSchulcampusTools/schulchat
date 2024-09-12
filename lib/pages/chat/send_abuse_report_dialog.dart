import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/utils/localized_exception_extension.dart';
import '../../widgets/matrix.dart';

class SendAbuseReportDialog extends StatefulWidget {
  final Room room;
  // final MatrixImageFile screenshot;
  final Uint8List screenshot;
  final Event event;

  const SendAbuseReportDialog({
    required this.room,
    required this.screenshot,
    required this.event,
    Key? key,
  }) : super(key: key);

  @override
  SendAbuseReportDialogState createState() => SendAbuseReportDialogState();
}

class SendAbuseReportDialogState extends State<SendAbuseReportDialog> {
  final reasonController = TextEditingController();
  int score = -100;

  Future<void> _send() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      Matrix.of(context).client.reportContent(
            widget.event.roomId.toString(),
            widget.event.eventId,
            reason: reasonController.text,
            score: score,
            img: base64.encode(widget.screenshot),
            school_id: widget.room.schoolId,
          );

      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(L10n.of(context)!.contentHasBeenReported)),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(e.toLocalizedString(context))),
      );
    }

    Navigator.of(context, rootNavigator: false).pop();

    return;
  }

  void unfocus() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    bool smallScreen = false;
    final mediaQueryData = MediaQuery.maybeOf(context);
    if (mediaQueryData != null) {
      smallScreen = mediaQueryData.size.width < 480;
    }

    final fontSize = smallScreen ? 14.0 : 16.0;

    final listTileStyle = TextStyle(fontSize: fontSize);

    final subHeadingStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
    );
    const subHeadingSpacing = EdgeInsetsDirectional.only(top: 18, bottom: 10);

    Widget contentWidget;

    contentWidget = SingleChildScrollView(
      // hide soft keyboard in view is dragged
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: GestureDetector(
        // hide soft keyboard onTap
        onTap: () => unfocus(), //FocusManager.instance.primaryFocus?.unfocus(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: 15),
                  child: Text(
                    L10n.of(context)!.whyDoYouWantToReportThis,
                    style: subHeadingStyle,
                  ),
                )
              ],
            ),
            Column(
              children: [
                TextField(
                  minLines: 3,
                  maxLines: 5,
                  controller: reasonController,
                ),
              ],
            ),
            Row(
              children: [
                Padding(
                  padding: subHeadingSpacing,
                  child: Text(
                    "Screenshot",
                    style: subHeadingStyle,
                  ),
                )
              ],
            ),
            Flexible(
              child: Image.memory(
                widget.screenshot,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );

    return AlertDialog(
      title: Text(L10n.of(context)!.reportAbuse),
      content: contentWidget,
      actions: <Widget>[
        TextButton(
          onPressed: () {
            // just close the dialog
            Navigator.of(context, rootNavigator: false).pop();
          },
          child: Text(L10n.of(context)!.cancel),
        ),
        TextButton(
          onPressed: _send,
          child: Text(L10n.of(context)!.send),
        ),
      ],
    );
  }
}
