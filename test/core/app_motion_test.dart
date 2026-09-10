import 'package:atlas/core/theme/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppMotion.reduceMotion', () {
    testWidgets('is false in a normal environment', (tester) async {
      late bool reduce;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              reduce = AppMotion.reduceMotion(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(reduce, isFalse);
    });

    testWidgets('follows disableAnimations from the MediaQuery',
        (tester) async {
      late bool reduce;
      late Duration duration;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                reduce = AppMotion.reduceMotion(context);
                duration = AppMotion.duration(context, AppMotion.standard);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(reduce, isTrue);
      expect(duration, Duration.zero);
    });
  });

  group('motion tokens', () {
    test('every UI duration stays under the 300 ms ceiling', () {
      for (final duration in [
        AppMotion.instant,
        AppMotion.fast,
        AppMotion.standard,
        AppMotion.emphasized,
      ]) {
        expect(duration.inMilliseconds, lessThanOrEqualTo(300));
      }
    });

    test('nothing enters or presses from zero scale', () {
      expect(AppMotion.enterScale, greaterThanOrEqualTo(0.92));
      expect(AppMotion.pressedScale, greaterThanOrEqualTo(0.92));
      expect(AppMotion.enterScale, lessThan(1.0));
      expect(AppMotion.pressedScale, lessThan(1.0));
    });
  });
}
