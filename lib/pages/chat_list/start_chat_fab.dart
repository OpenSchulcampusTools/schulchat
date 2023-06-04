import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:vrouter/vrouter.dart';

import '../../config/themes.dart';
import 'chat_list.dart';

class StartChatFloatingActionButton extends StatelessWidget {
  final ChatListController controller;

  const StartChatFloatingActionButton({Key? key, required this.controller})
      : super(key: key);

  void _onPressed(BuildContext context) {
    VRouter.of(context).to('/newgroup');
  }

  IconData get icon {
    return Icons.group_add_outlined;
  }

  String getLabel(BuildContext context) {
    return L10n.of(context)!.newGroup;
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
