import 'package:atlas/core/theme/app_motion.dart';
import 'package:atlas/widgets/pressable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child, {bool reduceMotion = false}) => MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: MaterialApp(home: Scaffold(body: Center(child: child))),
      );

  double currentScale(WidgetTester tester) =>
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;

  testWidgets('rests at full size and never below the press floor',
      (tester) async {
    await tester.pumpWidget(wrap(Pressable(
      onTap: () {},
      child: const SizedBox(width: 60, height: 60),
    )));

    expect(currentScale(tester), 1.0);

    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(Pressable)));
    await tester.pump();
    expect(currentScale(tester), AppMotion.pressedScale);
    expect(currentScale(tester), greaterThanOrEqualTo(0.92));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(currentScale(tester), 1.0);
  });

  testWidgets('a cancelled press returns to rest', (tester) async {
    await tester.pumpWidget(wrap(Pressable(
      onTap: () {},
      child: const SizedBox(width: 60, height: 60),
    )));

    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(Pressable)));
    await tester.pump();
    await gesture.cancel();
    await tester.pumpAndSettle();

    expect(currentScale(tester), 1.0);
  });

  testWidgets('does not scale under reduced motion', (tester) async {
    await tester.pumpWidget(wrap(
      Pressable(onTap: () {}, child: const SizedBox(width: 60, height: 60)),
      reduceMotion: true,
    ));

    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(Pressable)));
    await tester.pump();
    expect(currentScale(tester), 1.0);
    await gesture.up();
  });

  testWidgets('a disabled pressable neither scales nor fires', (tester) async {
    await tester.pumpWidget(wrap(const Pressable(
      onTap: null,
      child: SizedBox(width: 60, height: 60),
    )));

    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(Pressable)));
    await tester.pump();
    expect(currentScale(tester), 1.0);
    await gesture.up();
  });
}
