import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/features/add_transaction/ui/add_transaction_page.dart';
import 'package:personal_finance/features/dashboard/ui/dashboard_page.dart';
import 'package:personal_finance/features/settings/ui/settings_page.dart';
import 'package:personal_finance/features/statistics/ui/statistics_page.dart';
import 'package:personal_finance/features/transactions/ui/transactions_page.dart';

import 'package:personal_finance/data/repositories/settings_repository.dart';

import 'helpers/test_db.dart';

/// Finds a bottom nav tab by its label.
Finder _tab(String label) => find.bySemanticsLabel(label);

void main() {
  testApp('opens on Home and switches tabs', (tester, db) async {
    expect(find.byType(DashboardPage), findsOneWidget);

    await tester.tap(_tab('Transactions'));
    await tester.pumpAndSettle();
    expect(find.byType(TransactionsPage), findsOneWidget);

    await tester.tap(_tab('Statistics'));
    await tester.pumpAndSettle();
    expect(find.byType(StatisticsPage), findsOneWidget);

    await tester.tap(_tab('Settings'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);

    await tester.tap(_tab('Home'));
    await tester.pumpAndSettle();
    expect(find.byType(DashboardPage), findsOneWidget);
  });

  testApp('+ opens Add expense over the nav and closes again', (
    tester,
    db,
  ) async {
    // Tap the top half of the button, the part above the bar.
    final button = find.bySemanticsLabel('Add transaction');
    await tester.tapAt(tester.getCenter(button) - const Offset(0, 20));
    await tester.pumpAndSettle();

    expect(find.byType(AddTransactionPage), findsOneWidget);
    expect(find.bySemanticsLabel('Add transaction'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(AddTransactionPage), findsNothing);
    expect(find.byType(DashboardPage), findsOneWidget);
  });

  testApp('Settings > Appearance switches the theme', (tester, db) async {
    await tester.tap(_tab('Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(SettingsPage));
    expect(Theme.of(context).brightness, Brightness.dark);
    final saved = await tester.runAsync(() => SettingsRepository(db).load());
    expect(saved!.themeMode, ThemeMode.dark, reason: 'choice is saved');

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(Theme.of(context).brightness, Brightness.light);
  });

  testApp('Settings opens the design preview and goes back', (
    tester,
    db,
  ) async {
    await tester.tap(_tab('Settings'));
    await tester.pumpAndSettle();

    // The row is near the bottom; scroll it clear of the bottom nav.
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Design preview'),
      300,
      scrollable: scrollable,
    );
    await tester.drag(scrollable, const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Design preview'));
    await tester.pumpAndSettle();
    expect(find.text('Tokens'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
  });
}
