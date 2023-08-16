import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/chat/events/message.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/widgets/avatar.dart';
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
        leading: BackButton(color: Theme.of(context).colorScheme.onBackground),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backgroundColor: Colors.transparent,
        elevation: 0,
        // iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          L10n.of(context)!.readReceipts,
        ),
        actions: const [],
      ),
      extendBodyBehindAppBar: false,
      body: MaxWidthBody(
        withScrolling: true,
        maxWidth: 800,
        child: controller.roomsLoaded
            ? controller.panelItems.isNotEmpty
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ExpansionPanelList(
                        dividerColor: AppConfig.primaryColorLight,
                        expansionCallback: controller.expansionCallback,
                        children: controller.panelItems.values
                            .toList()
                            .asMap()
                            .keys
                            .toList()
                            .map((var index) {
                          final item =
                              controller.panelItems.values.elementAt(index);
                          final room = item.room!;
                          return ExpansionPanel(
                            canTapOnHeader: true,
                            isExpanded: item.isExpanded,
                            headerBuilder: (context, isExpanded) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: ListTile(
                                  tileColor: Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer
                                      .withAlpha(210),
                                  leading: Stack(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 6,
                                          bottom: 4,
                                        ),
                                        child: Avatar(
                                          mxContent: room.avatar,
                                          name: room.getLocalizedDisplayname(
                                            MatrixLocals(L10n.of(context)!),
                                          ),
                                          size: 38,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (item.hasToGiveReadReceipt)
                                        const Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Icon(
                                            Icons.mark_chat_read,
                                            color: AppConfig.primaryColor,
                                            size: 20,
                                          ),
                                        )
                                    ],
                                  ),
                                  title: Wrap(
                                    children: [
                                      Text(
                                        room.getLocalizedDisplayname(
                                          MatrixLocals(L10n.of(context)!),
                                        ),
                                        overflow: TextOverflow.clip,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            body: Padding(
                              padding: const EdgeInsets.only(bottom: 15),
                              child: item.messagesLoaded == true
                                  ? Column(
                                      children: [
                                        if (item.messages.isEmpty)
                                          Text(
                                            L10n.of(context)!
                                                .noReadReceiptRequestsFound,
                                          )
                                        else
                                          for (var message in item
                                              .messages.values
                                              .toList()
                                              .reversed)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                right: 25,
                                              ),
                                              child: Message(
                                                message,
                                                onSwipe: (swipeDirection) {},
                                                onReadReceipt: (event) =>
                                                    controller.onReadReceipt(
                                                  event,
                                                  item,
                                                  message,
                                                ),
                                                onSelect: (event) {},
                                                timeline: item.timeline!,
                                              ),
                                            ),
                                      ],
                                    )
                                  : const Center(
                                      child: CircularProgressIndicator.adaptive(
                                        strokeWidth: 2,
                                      ),
                                    ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  )
                : Center(
                    child: Text(L10n.of(context)!.noReadReceiptRequestsFound),
                  )
            : const Center(
                child: CircularProgressIndicator.adaptive(strokeWidth: 2),
              ),
      ),
    );
  }
}
