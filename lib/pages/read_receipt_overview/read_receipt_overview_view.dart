import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/chat/events/message.dart';
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
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          L10n.of(context)!.readReceipts,
        ),
        actions: [],
      ),
      extendBodyBehindAppBar: false,
      body: MaxWidthBody(
        withScrolling: true,
        maxWidth: 800,
        child: controller.roomsLoaded
            ? controller.panelItems.isNotEmpty
                ? Column(mainAxisSize: MainAxisSize.min, children: [
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
                                      leading: Avatar(
                                        mxContent: room.avatar,
                                        name: room.displayname,
                                      ),
                                      title: Row(children: [
                                        Text(room.displayname),
                                        if (item.hasToGiveReadReceipt)
                                          const Padding(
                                              padding:
                                                  EdgeInsets.only(left: 10),
                                              child: Icon(
                                                Icons.mark_chat_read_outlined,
                                                color: AppConfig.primaryColor,
                                                size: 20,
                                              ))
                                      ])));
                            },
                            body: Padding(
                                padding: const EdgeInsets.only(bottom: 15),
                                child: item.messagesLoaded == true
                                    ? Column(children: [
                                        if (item.messages.isEmpty)
                                          Text(L10n.of(context)!
                                              .noReadReceiptRequestsFound)
                                        else
                                          for (var message in item.messages)
                                            Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 25),
                                                child: Message(message,
                                                    onSwipe:
                                                        (swipeDirection) {},
                                                    onReadReceipt: (event) =>
                                                        controller
                                                            .onReadReceiptClick(
                                                                event, item),
                                                    onSelect: (event) {},
                                                    timeline: item.timeline!)),
                                      ])
                                    : const Center(
                                        child:
                                            CircularProgressIndicator.adaptive(
                                                strokeWidth: 2),
                                      )));
                      }).toList(),
                    ),
                  ])
                : Center(
                    child: Text(L10n.of(context)!.noReadReceiptRequestsFound))
            : const Center(
                child: CircularProgressIndicator.adaptive(strokeWidth: 2),
              ),
      ),
    );
  }
}