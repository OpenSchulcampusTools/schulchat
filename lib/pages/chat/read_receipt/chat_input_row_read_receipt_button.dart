import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';

import 'package:fluffychat/config/app_config.dart';
import '../chat.dart';

class ChatInputRowReadReceiptButton extends StatelessWidget {
  final ChatController controller;

  const ChatInputRowReadReceiptButton(this.controller, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (controller.showReadReceiptButton()) {
      if (controller.requireReadReceipt) {
        return IconButton(
          tooltip: L10n.of(context)!.readReceiptOff,
          icon: const Icon(
            Icons.mark_chat_read,
            color: AppConfig.primaryColor,
          ),
          onPressed: controller.toggleReadReceiptAction,
        );
      } else {
        return IconButton(
          tooltip: L10n.of(context)!.readReceiptOn,
          icon: const Icon(
            Icons.mark_chat_read_outlined,
            color: Colors.grey,
          ),
          onPressed: controller.toggleReadReceiptAction,
        );
      }
    } else {
      return Container();
    }
  }
}
