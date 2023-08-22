import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

enum PermissionLevel {
  user,
  admin,
}

extension on PermissionLevel {
  String toLocalizedString(BuildContext context) {
    switch (this) {
      case PermissionLevel.user:
        return L10n.of(context)!.user;
      case PermissionLevel.admin:
        return L10n.of(context)!.admin;
      default:
        return L10n.of(context)!.user;
    }
  }
}

Future<int?> showPermissionChooser(
  BuildContext context, {
  int currentLevel = 0,
}) async {
  final permissionLevel = await showConfirmationDialog(
    context: context,
    title: L10n.of(context)!.setPermissionsLevel,
    actions: PermissionLevel.values
        .map(
          (level) => AlertDialogAction(
            key: level,
            label: level.toLocalizedString(context),
          ),
        )
        .toList(),
  );
  if (permissionLevel == null) return null;

  switch (permissionLevel) {
    case PermissionLevel.user:
      return 0;
    case PermissionLevel.admin:
      return 100;
  }
}
