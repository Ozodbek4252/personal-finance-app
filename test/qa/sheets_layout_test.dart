import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_finance/app.dart';
import 'package:personal_finance/data/bootstrap.dart';
import 'package:personal_finance/router.dart';

import '../helpers/test_db.dart';

/// Sheets and dialogs on a small phone with big text. Any layout error
/// fails the test.
void main() {
  final cases = <(String, Future<void> Function(WidgetTester))>[
    (
      'filter sheet',
      (t) async {
        await t.tap(find.bySemanticsLabel('Transactions'));
        await t.pumpAndSettle();
        await t.tap(find.bySemanticsLabel('Filters'));
      },
    ),
    (
      'delete confirmation',
      (t) async {
        GoRouter.of(
          t.element(find.byType(Scaffold).first),
        ).push(Routes.transactionDetail(1));
        await t.pumpAndSettle();
        await t.tap(find.bySemanticsLabel('Delete transaction').first);
      },
    ),
    (
      'all categories sheet',
      (t) async {
        GoRouter.of(
          t.element(find.byType(Scaffold).first),
        ).push(Routes.addExpense);
        await t.pumpAndSettle();
        await t.tap(find.bySemanticsLabel('More categories'));
      },
    ),
    (
      'statistics week view',
      (t) async {
        await t.tap(find.bySemanticsLabel('Statistics'));
        await t.pumpAndSettle();
        await t.tap(find.text('Week'));
      },
    ),
  ];

  for (final (name, open) in cases) {
    testWidgets('$name · small phone, big text', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      final db = memoryDb();
      final overrides = (await tester.runAsync(
        () => bootstrap(db, sampleData: true),
      ))!;
      await tester.pumpWidget(
        ProviderScope(overrides: overrides, child: const PersonalFinanceApp()),
      );
      await tester.pumpAndSettle();
      await open(tester);
      await tester.pumpAndSettle();

      final scrollables = find.byType(Scrollable);
      if (scrollables.evaluate().isNotEmpty) {
        for (var i = 0; i < 6; i++) {
          await tester.drag(scrollables.last, const Offset(0, -300));
          await tester.pumpAndSettle();
        }
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await db.close();
    });
  }
}
