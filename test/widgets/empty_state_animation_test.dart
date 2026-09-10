import 'package:atlas/widgets/empty_state_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child, {bool ticking = true}) => MaterialApp(
        home: Scaffold(
          body: TickerMode(enabled: ticking, child: Center(child: child)),
        ),
      );

  testWidgets('falls back to a visible icon when the asset cannot be loaded',
      (tester) async {
    await tester.pumpWidget(wrap(const EmptyStateAnimation(
      asset: 'assets/images/does_not_exist.json',
      fallbackIcon: Icons.shopping_cart_outlined,
    )));
    await tester.pumpAndSettle();

    // The bare Lottie.asset draws nothing here, which hides the problem.
    expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
  });

  testWidgets('reserves its box even before the composition arrives',
      (tester) async {
    await tester.pumpWidget(wrap(const EmptyStateAnimation(
      asset: 'assets/images/does_not_exist.json',
      fallbackIcon: Icons.shopping_cart_outlined,
      size: 170,
    )));
    await tester.pump();

    final box = tester.getSize(find.byType(EmptyStateAnimation));
    expect(box, const Size(170, 170));
  });

  testWidgets('builds without a ticker when its tab is hidden', (tester) async {
    await tester.pumpWidget(wrap(
      const EmptyStateAnimation(
        asset: 'assets/images/does_not_exist.json',
        fallbackIcon: Icons.shopping_cart_outlined,
      ),
      ticking: false,
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(EmptyStateAnimation), findsOneWidget);
  });
}
