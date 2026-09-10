import 'package:atlas/widgets/animated_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';

void main() {
  Widget wrap(Widget child, {bool reduceMotion = false}) => MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: MaterialApp(home: Scaffold(bottomNavigationBar: child)),
      );

  List<NavBarItemData> items({int badgeCount = 0}) => [
        const NavBarItemData(
            icon: HugeIcons.strokeRoundedHome09, label: 'Home'),
        NavBarItemData(
          icon: HugeIcons.strokeRoundedShoppingCart01,
          label: 'Cart',
          badgeCount: badgeCount,
        ),
      ];

  testWidgets('tapping the current tab is a no-op', (tester) async {
    final taps = <int>[];
    await tester.pumpWidget(wrap(AnimatedBottomNavBar(
      currentIndex: 0,
      items: items(),
      onTap: taps.add,
    )));

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    expect(taps, isEmpty);
  });

  testWidgets('tapping a different tab reports it once', (tester) async {
    final taps = <int>[];
    await tester.pumpWidget(wrap(AnimatedBottomNavBar(
      currentIndex: 0,
      items: items(),
      onTap: taps.add,
    )));

    await tester.tap(find.text('Cart'));
    await tester.pumpAndSettle();

    expect(taps, [1]);
  });

  testWidgets('the indicator moves by transform, never by layout',
      (tester) async {
    await tester.pumpWidget(wrap(AnimatedBottomNavBar(
      currentIndex: 0,
      items: items(),
      onTap: (_) {},
    )));
    await tester.pumpAndSettle();

    // AnimatedPositioned would animate `left`; the replacement must not.
    expect(find.byType(AnimatedPositioned), findsNothing);
    expect(find.byType(TweenAnimationBuilder<double>), findsWidgets);
  });

  testWidgets('a zero badge renders nothing', (tester) async {
    await tester.pumpWidget(wrap(AnimatedBottomNavBar(
      currentIndex: 0,
      items: items(),
      onTap: (_) {},
    )));
    expect(find.text('0'), findsNothing);
  });

  testWidgets('a multi-digit badge renders its count', (tester) async {
    await tester.pumpWidget(wrap(AnimatedBottomNavBar(
      currentIndex: 0,
      items: items(badgeCount: 12),
      onTap: (_) {},
    )));
    await tester.pumpAndSettle();
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('each tab is a selectable button for assistive tech',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(AnimatedBottomNavBar(
      currentIndex: 1,
      items: items(badgeCount: 3),
      onTap: (_) {},
    )));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.bySemanticsLabel('Cart')),
      matchesSemantics(
        label: 'Cart',
        value: '3',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });
}
