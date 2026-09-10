import 'package:atlas/themes/colors.dart';
import 'package:atlas/widgets/filter_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(body: Center(child: child)),
      );

  Color? pillColor(WidgetTester tester) {
    final container =
        tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
    return (container.decoration as BoxDecoration?)?.color;
  }

  testWidgets('an inactive pill shows no clear button', (tester) async {
    await tester.pumpWidget(wrap(FilterPill(
      label: 'Brands',
      isActive: false,
      onTap: () {},
      onClear: () {},
    )));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.close), findsNothing);
    expect(pillColor(tester), isNot(AppColors.green));
  });

  testWidgets('an active pill fills and offers a clear button', (tester) async {
    await tester.pumpWidget(wrap(FilterPill(
      label: 'Brands',
      isActive: true,
      onTap: () {},
      onClear: () {},
    )));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(pillColor(tester), AppColors.green);
  });

  testWidgets('clearing does not also trigger the pill itself', (tester) async {
    var taps = 0;
    var clears = 0;
    await tester.pumpWidget(wrap(FilterPill(
      label: 'Brands',
      isActive: true,
      onTap: () => taps++,
      onClear: () => clears++,
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(clears, 1);
    expect(taps, 0);
  });

  testWidgets('reports its selected state to assistive tech', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(FilterPill(
      label: 'Brands',
      isActive: true,
      onTap: () {},
    )));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.bySemanticsLabel('Brands')),
      matchesSemantics(
        label: 'Brands',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });
}
