import 'package:flutter_test/flutter_test.dart';

import 'package:fluffychat/widgets/lock_screen.dart';

void main() {
  testWidgets('lock screen', (WidgetTester tester) async {
    await tester.pumpWidget(LockScreen());

    expect(find.text('Please enter your pin'), findsOneWidget);
  });
}
