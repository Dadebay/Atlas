import 'package:atlas/widgets/animated_quantity_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const style = TextStyle(fontSize: 16);

  Widget wrap(int quantity, {bool reduceMotion = false}) => MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedQuantityText(quantity: quantity, style: style),
            ),
          ),
        ),
      );

  testWidgets('shows the current quantity', (tester) async {
    await tester.pumpWidget(wrap(3));
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('crossfades to the new value and leaves only that value',
      (tester) async {
    await tester.pumpWidget(wrap(3));
    await tester.pumpWidget(wrap(4));
    await tester.pump(const Duration(milliseconds: 40));

    // Mid-transition both digits exist; that is the crossfade.
    expect(find.text('4'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('3'), findsNothing);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('does not slide under reduced motion', (tester) async {
    await tester.pumpWidget(wrap(1, reduceMotion: true));
    await tester.pumpWidget(wrap(2, reduceMotion: true));
    await tester.pump(const Duration(milliseconds: 40));

    // Scoped to this widget: the enclosing route has slide transitions of its
    // own that have nothing to do with the counter.
    expect(
      find.descendant(
        of: find.byType(AnimatedQuantityText),
        matching: find.byType(SlideTransition),
      ),
      findsNothing,
    );
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('rapid changes retarget instead of queueing', (tester) async {
    await tester.pumpWidget(wrap(1));
    for (var q = 2; q <= 5; q++) {
      await tester.pumpWidget(wrap(q));
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.pumpAndSettle();

    expect(find.text('5'), findsOneWidget);
    for (final stale in ['1', '2', '3', '4']) {
      expect(find.text(stale), findsNothing);
    }
  });
}
