import 'package:fluffychat/pages/chat_list/client_chooser_button.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'wait_for.dart';

extension RemoveDevicesExtension on WidgetTester {
  Future<void> removeAllDevices(password) async {
    await waitFor(find.byType(ClientChooserButton));
    await tap(find.byType(ClientChooserButton));
    await pumpAndSettle();
    await waitFor(find.text('Settings'));
    await tap(find.text('Settings'));
    await waitFor(
      find.text('Devices'),
      skipPumpAndSettle: true,
    );
    await tap(find.text('Devices'));
    await pumpAndSettle();
    if (!find.text('No other devices found').evaluate().isNotEmpty) {
      try {
        await waitFor(find.text('Remove all other devices'));
        await tap(find.text('Remove all other devices'));
        await pumpAndSettle();
        await waitFor(find.maybeUppercaseText('Yes'));
        await tap(find.maybeUppercaseText('Yes'));
        await pumpAndSettle();
        await enterText(find.byType(TextField), password);
        await pumpAndSettle();
        await tap(find.maybeUppercaseText('Ok'));
        await pumpAndSettle();
      } catch (_) {}
    }
  }
}
