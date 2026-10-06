import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_finance/app.dart';
import 'package:personal_finance/core/theme/theme_mode_provider.dart';
import 'package:personal_finance/data/bootstrap.dart';
import 'package:personal_finance/router.dart';

import '../helpers/test_db.dart';

/// Every screen, opened in a few phone setups. Any layout error (like a
/// "RenderFlex overflowed") fails the test.
void main() {
  const setups = [
    (name: 'phone light', size: Size(390, 844), scale: 1.0, dark: false),
    (name: 'phone dark', size: Size(390, 844), scale: 1.0, dark: true),
    (
      name: 'small phone, big text',
      size: Size(320, 568),
      scale: 1.3,
      dark: false,
    ),
  ];

  // (label, how to open it). Tabs are tapped; other pages are pushed.
  final screens = <(String, String?)>[
    ('Home', null),
    ('Transactions', null),
    ('Statistics', null),
    ('Settings', null),
    ('Add expense', Routes.addExpense),
    ('Add income', Routes.addIncome),
    ('Transaction details', Routes.transactionDetail(1)),
    ('Edit transaction', Routes.editTransaction(1)),
    ('Monthly overview', Routes.monthlyOverview),
    ('Categories', Routes.categories),
    ('New category', Routes.newCategory),
    ('Payment methods', Routes.paymentMethods),
    ('Currencies', Routes.currencies),
  ];

  for (final setup in setups) {
    for (final (label, route) in screens) {
      testWidgets('$label · ${setup.name}', (tester) async {
        tester.view.physicalSize = setup.size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = setup.scale;
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearAllTestValues);

        final db = memoryDb();
        final overrides = (await tester.runAsync(
          () => bootstrap(db, sampleData: true),
        ))!;
        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides,
            child: const PersonalFinanceApp(),
          ),
        );
        await tester.pumpAndSettle();
        if (setup.dark) {
          final container = ProviderScope.containerOf(
            tester.element(find.byType(PersonalFinanceApp)),
          );
          await tester.runAsync(
            () =>
                container.read(themeModeProvider.notifier).set(ThemeMode.dark),
          );
          await tester.pumpAndSettle();
        }

        if (route == null) {
          await tester.tap(find.bySemanticsLabel(label));
        } else {
          GoRouter.of(tester.element(find.byType(Scaffold).first)).push(route);
        }
        await tester.pumpAndSettle();

        // Scroll through the page so every part gets built and laid out.
        final scrollables = find.byType(Scrollable);
        if (scrollables.evaluate().isNotEmpty) {
          for (var i = 0; i < 8; i++) {
            await tester.drag(scrollables.first, const Offset(0, -400));
            await tester.pumpAndSettle();
          }
        }

        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await db.close();
      });
    }
  }
}
