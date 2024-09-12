import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:badges/badges.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:keyboard_shortcuts/keyboard_shortcuts.dart';
import 'package:vrouter/vrouter.dart';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/chat_list/navi_rail_item.dart';
import 'package:fluffychat/widgets/unread_rooms_badge.dart';
import '../../widgets/matrix.dart';
import 'chat_list_body.dart';
import 'start_chat_fab.dart';

class ChatListView extends StatelessWidget {
  final ChatListController controller;

  const ChatListView(this.controller, {Key? key}) : super(key: key);

  List<NavigationDestination> getNavigationDestinations(BuildContext context) {
    final badgePosition = BadgePosition.topEnd(top: -12, end: -8);
    return [
      if (AppConfig.separateChatTypes) ...[
        NavigationDestination(
          icon: UnreadRoomsBadge(
            badgePosition: badgePosition,
            filter: controller.getRoomFilterByActiveFilter(ActiveFilter.groups),
            child: const Icon(Icons.groups_outlined),
          ),
          selectedIcon: UnreadRoomsBadge(
            badgePosition: badgePosition,
            filter: controller.getRoomFilterByActiveFilter(ActiveFilter.groups),
            child: const Icon(Icons.groups),
          ),
          label: L10n.of(context)!.groups,
        ),
        NavigationDestination(
          icon: UnreadRoomsBadge(
            badgePosition: badgePosition,
            filter:
                controller.getRoomFilterByActiveFilter(ActiveFilter.messages),
            child: const Icon(Icons.chat_outlined),
          ),
          selectedIcon: UnreadRoomsBadge(
            badgePosition: badgePosition,
            filter:
                controller.getRoomFilterByActiveFilter(ActiveFilter.messages),
            child: const Icon(Icons.chat),
          ),
          label: L10n.of(context)!.messages,
        ),
      ] else
        NavigationDestination(
          icon: UnreadRoomsBadge(
            badgePosition: badgePosition,
            filter:
                controller.getRoomFilterByActiveFilter(ActiveFilter.allChats),
            child: const Icon(Icons.chat_outlined),
          ),
          selectedIcon: UnreadRoomsBadge(
            badgePosition: badgePosition,
            filter:
                controller.getRoomFilterByActiveFilter(ActiveFilter.allChats),
            child: const Icon(Icons.chat),
          ),
          label: L10n.of(context)!.chats,
        ),
      for (final schoolId in controller.schools.keys) ...[
        NavigationDestination(
          icon: UnreadRoomsBadge(
            badgePosition: badgePosition,
            filter: controller.getRoomFilterBySchool(schoolId),
            child: const Icon(Icons.chat_outlined),
          ),
          selectedIcon: UnreadRoomsBadge(
            badgePosition: badgePosition,
            filter: controller.getRoomFilterBySchool(schoolId),
            child: const Icon(Icons.chat),
          ),
          label: controller.schools[schoolId]!,
        ),
      ]
    ];
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Object?>(
      stream: Matrix.of(context).onShareContentChanged.stream,
      builder: (_, __) {
        final selectMode = controller.selectMode;
        return VWidgetGuard(
          onSystemPop: (redirector) async {
            final selMode = controller.selectMode;
            if (selMode != SelectMode.normal) {
              controller.cancelAction();
              redirector.stopRedirection();
              return;
            }
            if (controller.activeFilter !=
                (AppConfig.separateChatTypes
                    ? ActiveFilter.messages
                    : ActiveFilter.allChats)) {
              controller
                  .onDestinationSelected(AppConfig.separateChatTypes ? 1 : 0);
              redirector.stopRedirection();
              return;
            }
          },
          child: Row(
            children: [
              if (FluffyThemes.isColumnMode(context) &&
                  FluffyThemes.getDisplayNavigationRail(context)) ...[
                Builder(
                  builder: (context) {
                    final destinations = getNavigationDestinations(context);

                    return SizedBox(
                      width: FluffyThemes.navRailWidth,
                      child: ListView.builder(
                        scrollDirection: Axis.vertical,
                        itemCount: destinations.length,
                        itemBuilder: (context, i) {
                          if (i < destinations.length) {
                            return NaviRailItem(
                              isSelected: i == controller.selectedIndex,
                              onTap: () => controller.onDestinationSelected(i),
                              icon: destinations[i].icon,
                              selectedIcon: destinations[i].selectedIcon,
                              toolTip: destinations[i].label,
                            );
                          }
                          i -= destinations.length;
                          return null;
                        },
                      ),
                    );
                  },
                ),
                Container(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ],
              Expanded(
                child: GestureDetector(
                  onTap: FocusManager.instance.primaryFocus?.unfocus,
                  excludeFromSemantics: true,
                  behavior: HitTestBehavior.translucent,
                  child: Scaffold(
                    body: ChatListViewBody(controller),
                    bottomNavigationBar: controller.displayNavigationBar
                        ? NavigationBar(
                            height: 64,
                            selectedIndex: controller.selectedIndex,
                            onDestinationSelected:
                                controller.onDestinationSelected,
                            destinations: getNavigationDestinations(context),
                          )
                        : null,
                    floatingActionButton: KeyBoardShortcuts(
                      keysToPress: {
                        LogicalKeyboardKey.controlLeft,
                        LogicalKeyboardKey.keyN
                      },
                      onKeysPressed: () =>
                          VRouter.of(context).to('/newgroupchat'),
                      helpLabel: L10n.of(context)!.createNewGroup,
                      child: selectMode == SelectMode.normal &&
                              controller.filteredRooms.isNotEmpty &&
                              !controller.isSearchMode
                          ? StartChatFloatingActionButton(
                              activeFilter: controller.activeFilter,
                              roomsIsEmpty: false,
                              scrolledToTop: controller.scrolledToTop,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
