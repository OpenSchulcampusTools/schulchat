import 'package:flutter_test/flutter_test.dart';

/// Workaround for https://github.com/flutter/flutter/issues/88765
extension WaitForExtension on WidgetTester {
  Future<void> waitFor(
    Finder finder, {
    Duration timeout = const Duration(seconds: 20),
    bool skipPumpAndSettle = false,
  }) async {
    final end = DateTime.now().add(timeout);

    do {
      if (DateTime.now().isAfter(end)) {
        throw Exception('Timed out waiting for $finder');
      }

      if (!skipPumpAndSettle) {
        await pumpAndSettle();
      }
      await Future.delayed(const Duration(milliseconds: 100));
    } while (finder.evaluate().isEmpty);
  }
}

Future<void> waitForFairkom(tester, condition, expectation, duration) async {
  const defaultDelay = 100;
  final iterations = duration/defaultDelay;
  var found = false;
  var lastException;
  for (var i = 0; i < iterations; i++) {
    await Future.delayed(const Duration(milliseconds: defaultDelay));
    await tester.pumpAndSettle();
    try {
      expect(condition, expectation);
      found = true;
      break;
    } catch (exception){
      print('not found $i');
      lastException = exception;
    }
  }
  if (!found) {
    throw lastException;
  }
}

Future<void> pumpX(WidgetTester tester, {int rounds = 5}) async {
  for (int i = 0; i < rounds; i++) {
    // because pumpAndSettle doesn't work
    await tester.pump(const Duration(seconds: 1));
  }
}

extension MaybeUppercaseFinder on CommonFinders {
  /// On Android some button labels are in uppercase while on iOS they
  /// are not. This method tries both.
  Finder maybeUppercaseText(
    String text, {
    bool findRichText = false,
    bool skipOffstage = true,
  }) {
    try {
      final finder = find.text(
        text.toUpperCase(),
        findRichText: findRichText,
        skipOffstage: skipOffstage,
      );
      expect(finder, findsOneWidget);
      return finder;
    } catch (_) {
      return find.text(
        text,
        findRichText: findRichText,
        skipOffstage: skipOffstage,
      );
    }
  }
}
