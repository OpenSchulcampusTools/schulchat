import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';
import 'package:video_player/video_player.dart';

import 'read_receipt_overview_view.dart';

class ReadReceiptOverviewPage extends StatefulWidget {
  const ReadReceiptOverviewPage({Key? key}) : super(key: key);

  @override
  ReadReceiptOverviewController createState() =>
      ReadReceiptOverviewController();
}

class ReadReceiptOverviewController extends State<ReadReceiptOverviewPage> {
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();
  late Color backgroundColor;
  late Color backgroundColorDark;
  MatrixImageFile? image;
  MatrixVideoFile? video;

  VideoPlayerController? videoPlayerController;

  bool get hasMedia => image != null || video != null;

  bool hasText = false;

  bool textFieldHasFocus = false;

  BoxFit fit = BoxFit.contain;

  int alignmentX = 0;
  int alignmentY = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ReadReceiptOverviewView(this);
}
