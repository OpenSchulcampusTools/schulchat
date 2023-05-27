import 'package:flutter/material.dart';

import 'package:vrouter/vrouter.dart';

import '../../config/themes.dart';
import 'chat_list.dart';

class StartChatFloatingActionButton extends StatelessWidget {
  final ChatListController controller;

  const StartChatFloatingActionButton({Key? key, required this.controller})
      : super(key: key);

  void _onPressed(BuildContext context) {
    switch (controller.activeFilter) {
      case ActiveFilter.allChats:
      case ActiveFilter.messages:
        VRouter.of(context).to('/newgroup');
        break;
      case ActiveFilter.groups:
        VRouter.of(context).to('/newgroup');
        break;
      case ActiveFilter.spaces:
        VRouter.of(context).to('/newspace');
        break;
    }
  }

  IconData get icon {
    switch (controller.activeFilter) {
      case ActiveFilter.allChats:
      case ActiveFilter.messages:
        return Icons.edit_outlined;
      case ActiveFilter.groups:
        return Icons.group_add_outlined;
      case ActiveFilter.spaces:
        return Icons.workspaces_outlined;
    }
  }

  String getLabel(BuildContext context) {
    return 'Neuer Raum'; //L10n.of(context)!.newGroup;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: FluffyThemes.animationDuration,
      curve: FluffyThemes.animationCurve,
      width: controller.filteredRooms.isEmpty
          ? null
          : controller.scrolledToTop
              ? 144
              : 56,
      child: controller.scrolledToTop
          ? FloatingActionButton.extended(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              onPressed: () => _onPressed(context),
              icon: Icon(icon),
              label: Text(
                getLabel(context),
                overflow: TextOverflow.fade,
              ),
            )
          : FloatingActionButton(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              onPressed: () => _onPressed(context),
              child: Icon(icon),
            ),
    );
  }
}
