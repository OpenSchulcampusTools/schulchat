import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';

import 'package:fluffychat/widgets/layouts/max_width_body.dart';
import 'read_receipt_overview.dart';

class ReadReceiptOverviewView extends StatelessWidget {
  final ReadReceiptOverviewController controller;
  const ReadReceiptOverviewView(this.controller, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        //backgroundColor: color,
        appBar: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle.light,
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            L10n.of(context)!.readReceipts,
          ),
          actions: [],
        ),
        extendBodyBehindAppBar: true,
        body: MaxWidthBody());
  }
}
