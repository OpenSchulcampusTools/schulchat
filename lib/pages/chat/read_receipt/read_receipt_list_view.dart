import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';

import 'package:fluffychat/pages/chat/read_receipt/read_receipt_list.dart';
import '../../../config/app_config.dart';
import '../../chat_details/participant_list_item.dart';

class ReadReceiptListView extends StatelessWidget {
  final ReadReceiptListController controller;

  const ReadReceiptListView(this.controller, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isSmallScreen = false;
    final mediaQueryData = MediaQuery.maybeOf(context);
    if (mediaQueryData != null) {
      isSmallScreen = mediaQueryData.size.width < 468;
    }

    return controller.membersLoaded
        ? ListView.builder(
            itemCount: controller.members.length + 1,
            itemBuilder: (BuildContext context, int i) => i == 0
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: SizedBox(
                      height: (isSmallScreen) ? 105 : 55,
                      child: Flex(
                        direction:
                            (isSmallScreen) ? Axis.vertical : Axis.horizontal,
                        mainAxisAlignment: (isSmallScreen)
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: RadioListTile(
                              title: Text(L10n.of(context)!.all),
                              value: "all",
                              groupValue: controller.filter,
                              onChanged: (value) =>
                                  controller.changeFilter(value),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile(
                              title: Text(L10n.of(context)!.open),
                              value: "open",
                              groupValue: controller.filter,
                              onChanged: (value) =>
                                  controller.changeFilter(value),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile(
                              title: Text(L10n.of(context)!.confirmed),
                              value: "given",
                              groupValue: controller.filter,
                              onChanged: (value) =>
                                  controller.changeFilter(value),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : controller.userIsVisible(i - 1)
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 18),
                            child: controller.userHasGivenReadReceipt(i - 1)
                                ? const Icon(
                                    Icons.mark_chat_read,
                                    color: AppConfig.primaryColor,
                                  )
                                : const Icon(
                                    Icons.mark_chat_read_outlined,
                                    color: AppConfig.primaryColor,
                                  ),
                          ),
                          Expanded(
                            child: ParticipantListItem(
                              controller.members[i - 1],
                            ),
                          )
                        ],
                      )
                    : Container(),
          )
        : const Center(
            child: CircularProgressIndicator.adaptive(strokeWidth: 2),
          );
  }
}
