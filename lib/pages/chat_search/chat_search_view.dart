import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';
import 'package:vrouter/vrouter.dart';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/chat/events/message.dart';
import 'package:fluffychat/pages/chat_search/chat_search.dart';
import 'package:fluffychat/utils/fluffy_share.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/widgets/chat_settings_popup_menu.dart';
import 'package:fluffychat/widgets/content_banner.dart';
import 'package:fluffychat/widgets/layouts/max_width_body.dart';
import 'package:fluffychat/widgets/matrix.dart';

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
      return FutureBuilder<bool>(
          future: controller.getTimeline(),
          builder: (BuildContext context, snapshot) {
            return Scaffold(
              floatingActionButton: controller.showScrollToTopButton
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 56.0),
                      child: FloatingActionButton(
                        heroTag: "searchBackToTop",
                        onPressed: controller.scrollToTop,
                        mini: true,
                        child: const Icon(Icons.arrow_upward_outlined),
                      ))
                  : null,
              body: NestedScrollView(
                controller: controller.scrollController,
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
                  child: StreamBuilder<List<Event>>(
                      stream: controller.searchResultStreamController.stream,
                      builder: (context, snapshot) {
                        // put search field and button inside ListView, this way they are scrollable and
                        // pixel overflow errors on small screens are avoided (as anything is scrollable)
                        return ListView.builder(
                            itemCount: (snapshot.hasData
                                ? snapshot.data!.length + 1
                                : 1),
                            itemBuilder: (BuildContext context, int i) => i == 0
                                ? Column(children: <Widget>[
                                    Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: TextField(
                                          controller:
                                              controller.searchController,
                                          onSubmitted: (value) {
                                            controller.search();
                                          },
                                          autofocus: true,
                                          decoration: InputDecoration(
                                            prefixIcon: const Icon(Icons.label),
                                            label:
                                                Text(L10n.of(context)!.search),
                                            errorText: controller.searchError,
                                          ),
                                        )),
                                    ButtonBar(
                                      children: [
                                        TextButton(
                                          onPressed: controller.search,
                                          child: Text(L10n.of(context)!.search),
                                        ),
                                      ],
                                    ),
                                    if (!controller.searchResultsFound)
                                      if (controller.searchState ==
                                              SearchState.noResult ||
                                          controller.searchState ==
                                              SearchState.finished)
                                        ListTile(
                                            title: Text(L10n.of(context)!
                                                .noSearchResult))
                                      else if (controller.searchState ==
                                          SearchState.searching)
                                        const Center(
                                          child: CircularProgressIndicator
                                              .adaptive(strokeWidth: 2),
                                        ),
                                  ])
                                : controller.searchResultsFound
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: <Widget>[
                                            Message(
                                              snapshot.data![i - 1],
                                              onSwipe: (direction) => {},
                                              onSelect:
                                                  controller.onSelectMessage,
                                              scrollToEventId:
                                                  controller.scrollToEventId,
                                              timeline: controller.timeline!,
                                              searchTerm: controller.searchTerm,
                                            ),
                                            if (i == snapshot.data?.length &&
                                                controller.searchState ==
                                                    SearchState.searching)
                                              const Center(
                                                child: CircularProgressIndicator
                                                    .adaptive(strokeWidth: 2),
                                              ),
                                          ])
                                    : Container());
                      }),
                ),
              ),
            );
          });
    }
  }
}
