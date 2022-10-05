import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/chat/events/message.dart';
import 'package:fluffychat/pages/chat_search/chat_search.dart';
import 'package:fluffychat/utils/fluffy_share.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions.dart/matrix_locals.dart';
import 'package:fluffychat/widgets/chat_settings_popup_menu.dart';
import 'package:fluffychat/widgets/content_banner.dart';
import 'package:fluffychat/widgets/layouts/max_width_body.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';

import 'package:fluffychat/widgets/matrix.dart';
import 'package:vrouter/vrouter.dart';

class ChatSearchView extends StatelessWidget {
  final ChatSearchController controller;

  const ChatSearchView(this.controller, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final room = Matrix.of(context).client.getRoomById(controller.roomId!);
    if (room == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(L10n.of(context)!.oopsSomethingWentWrong),
        ),
        body: Center(
          child: Text(L10n.of(context)!.youAreNoLongerParticipatingInThisChat),
        ),
      );
    } else {
      return StreamBuilder(
          stream: room.onUpdate.stream,
          builder: (context, snapshot) {
            return Scaffold(
              body: NestedScrollView(
                headerSliverBuilder:
                    (BuildContext context, bool innerBoxIsScrolled) => <Widget>[
                  SliverAppBar(
                    leading: IconButton(
                      icon: const Icon(Icons.close_outlined),
                      onPressed: () =>
                          VRouter.of(context).path.startsWith('/spaces/')
                              ? VRouter.of(context).pop()
                              : VRouter.of(context)
                                  .toSegments(['rooms', controller.roomId!]),
                    ),
                    elevation: Theme.of(context).appBarTheme.elevation,
                    expandedHeight: 300.0,
                    floating: true,
                    pinned: true,
                    actions: <Widget>[
                      if (room.canonicalAlias.isNotEmpty)
                        IconButton(
                          tooltip: L10n.of(context)!.share,
                          icon: Icon(Icons.adaptive.share_outlined),
                          onPressed: () => FluffyShare.share(
                              AppConfig.inviteLinkPrefix + room.canonicalAlias,
                              context),
                        ),
                      ChatSettingsPopupMenu(room, false)
                    ],
                    title: Text(
                      room.getLocalizedDisplayname(
                          MatrixLocals(L10n.of(context)!)),
                    ),
                    backgroundColor:
                        Theme.of(context).appBarTheme.backgroundColor,
                    flexibleSpace: FlexibleSpaceBar(
                      background: ContentBanner(
                        mxContent: room.avatar,
                        onEdit: null,
                        defaultIcon: Icons.group_outlined,
                      ),
                    ),
                  ),
                ],
                body: MaxWidthBody(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            controller: controller.searchController,
                            onSubmitted: (value) {
                              controller.search();
                            },
                            autofocus: true,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.label),
                              label: Text(L10n.of(context)!.search),
                              errorText: controller.searchError,
                            ),
                          ),
                        ),
                        ButtonBar(
                          children: [
                            TextButton(
                              onPressed: controller.search,
                              child: Text(L10n.of(context)!.search),
                            ),
                          ],
                        ),
                        Expanded(
                          child:  Builder(builder: (context) {
                                if (controller.searchResult.isEmpty) {
                                  return ListTile(
                                      title: Text("Keine Suchergebnisse"));
                                } else {
                                  return ListView.builder(
                                      itemCount: controller.searchResult.length,
                                      itemBuilder:
                                          (BuildContext context, int i) {
                                        return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: <Widget>[
                                              Message(
                                                  controller.searchResult[i],
                                                  onSwipe: (direction) => {},
                                                  unfold: controller.unfold,
                                                //  onInfoTab: controller.onInfoTab,
                                                  onSelect: controller.onSelectMessage,
                                                  timeline:
                                                      controller.timeline!)
                                            ]);
                                      });
                                }
                              }),
                        )
                      ]),
                ),
              ),
            );
          });
    }
  }
}
