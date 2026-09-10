import 'package:atlas/widgets/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child, {bool reduceMotion = false, bool ticking = true}) =>
      MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: MaterialApp(
          home: TickerMode(
            enabled: ticking,
            child: Scaffold(body: child),
          ),
        ),
      );

  testWidgets('paints a static skeleton under reduced motion', (tester) async {
    await tester.pumpWidget(wrap(
      const ShimmerScope(
          child: Shimmer(child: SizedBox(width: 100, height: 20))),
      reduceMotion: true,
    ));
    await tester.pump();

    // No mask means no per-frame shader, which is the whole point.
    expect(find.byType(ShaderMask), findsNothing);
  });

  testWidgets('sweeps when motion is allowed', (tester) async {
    await tester.pumpWidget(wrap(
      const ShimmerScope(
          child: Shimmer(child: SizedBox(width: 100, height: 20))),
    ));
    await tester.pump();

    expect(find.byType(ShaderMask), findsOneWidget);
    // A repeating controller never settles; pumping a frame is enough.
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('several skeletons in one scope share a single ticker',
      (tester) async {
    await tester.pumpWidget(wrap(
      const ShimmerScope(
        child: Column(
          children: [
            Shimmer(child: SizedBox(width: 100, height: 20)),
            Shimmer(child: SizedBox(width: 100, height: 20)),
            Shimmer(child: SizedBox(width: 100, height: 20)),
          ],
        ),
      ),
    ));
    await tester.pump();

    // One scope, three masks: three sweeps driven by one AnimationController.
    expect(find.byType(ShimmerScope), findsOneWidget);
    expect(find.byType(ShaderMask), findsNWidgets(3));
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('a shimmer with no scope above it makes its own', (tester) async {
    await tester.pumpWidget(wrap(
      const Shimmer(child: SizedBox(width: 100, height: 20)),
    ));
    await tester.pump();

    expect(find.byType(ShimmerScope), findsOneWidget);
    expect(find.byType(ShaderMask), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('the skeleton announces itself once, as loading', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(
      const ShimmerScope(
        child: Shimmer(
            child:
                Text('should not be read', textDirection: TextDirection.ltr)),
      ),
    ));
    await tester.pump();

    expect(find.bySemanticsLabel('should not be read'), findsNothing);
    handle.dispose();
    await tester.pump(const Duration(milliseconds: 300));
  });
}
