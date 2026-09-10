import 'dart:async';

import 'package:atlas/shared/connection_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:atlas/widgets/pressable.dart';

void main() {
  Widget wrap(Widget child) => GetMaterialApp(home: Scaffold(body: child));

  testWidgets('offers a retry and reports it once per tap', (tester) async {
    var retries = 0;
    await tester.pumpWidget(wrap(ConnectionErrorView(
      onRetry: () async => retries++,
      title: 'No connection',
      description: 'Check your network.',
    )));

    expect(find.text('No connection'), findsOneWidget);
    expect(find.text('Check your network.'), findsOneWidget);

    await tester.tap(find.byType(Pressable));
    await tester.pumpAndSettle();
    expect(retries, 1);
  });

  testWidgets('shows progress while a retry is in flight and ignores repeats',
      (tester) async {
    final gate = Completer<void>();
    var retries = 0;

    await tester.pumpWidget(wrap(ConnectionErrorView(
      onRetry: () async {
        retries++;
        await gate.future;
      },
      title: 'No connection',
    )));

    await tester.tap(find.byType(Pressable));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // A second tap while the first retry is still running must not queue.
    await tester.tap(find.byType(Pressable));
    await tester.pump();
    expect(retries, 1);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('a failed retry leaves the state usable again', (tester) async {
    var retries = 0;
    await tester.pumpWidget(wrap(ConnectionErrorView(
      onRetry: () async {
        retries++;
        throw Exception('still offline');
      },
      title: 'No connection',
    )));

    await tester.tap(find.byType(Pressable));
    await tester.pumpAndSettle();

    // The failure is swallowed rather than thrown at the gesture callback, and
    // the button must not be left spinning.
    expect(tester.takeException(), isNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.byType(Pressable));
    await tester.pumpAndSettle();
    expect(retries, 2);
  });
}
