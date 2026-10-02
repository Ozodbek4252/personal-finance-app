import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/data/repositories/settings_repository.dart';
import 'package:personal_finance/features/add_transaction/ui/add_transaction_page.dart';
import 'package:personal_finance/features/dashboard/ui/widgets/empty_dashboard.dart';

import '../../helpers/test_db.dart';

/// Scrolls the Dashboard until [finder] is on screen and clear of the
/// bottom nav, which floats over the lower part of the page.
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  final scrollable = find.byType(Scrollable).first;
  await tester.scrollUntilVisible(finder, 300, scrollable: scrollable);
  final navTop = tester.getTopLeft(find.bySemanticsLabel('Home')).dy - 40;
  final bottom = tester.getBottomLeft(finder).dy;
  if (bottom > navTop) {
    await tester.drag(scrollable, Offset(0, navTop - bottom - 20));
    await tester.pumpAndSettle();
  }
}

void main() {
  testApp('shows the sample month like the design', sampleData: true, (
    tester,
    db,
  ) async {
    expect(find.text('Wednesday, 30 September'), findsOneWidget);
    expect(find.text('September 2026'), findsOneWidget);
    expect(find.text('15 500 000'), findsOneWidget);
    expect(find.text('3.3% vs Aug'), findsOneWidget);
    expect(find.text('28.7% vs Aug'), findsOneWidget);
    expect(find.text('80% of income'), findsOneWidget);

    await _scrollTo(tester, find.text('Where your money went'));
    expect(find.text('27%'), findsOneWidget);
    expect(find.text('3 more categories · 850 000 UZS'), findsOneWidget);

    await _scrollTo(tester, find.text('29% vs Aug'));
    expect(find.text('Spent in September'), findsOneWidget);

    await _scrollTo(tester, find.text('Recent'));
    await _scrollTo(tester, find.text('Korzinka · 13:40'));
    expect(find.text('September salary · 10:05'), findsOneWidget);
  });

  testApp('hide balance is saved', sampleData: true, (tester, db) async {
    await tester.tap(find.bySemanticsLabel('Hide balance'));
    await tester.pumpAndSettle();
    expect(find.text('••••••'), findsOneWidget);
    final saved = await tester.runAsync(() => SettingsRepository(db).load());
    expect(saved!.balanceHidden, isTrue);

    await tester.tap(find.bySemanticsLabel('Show balance'));
    await tester.pumpAndSettle();
    expect(find.text('••••••'), findsNothing);
  });

  testApp('month picker switches the month', sampleData: true, (
    tester,
    db,
  ) async {
    await tester.tap(find.text('September 2026'));
    await tester.pumpAndSettle();
    expect(find.text('Choose month'), findsOneWidget);

    await tester.tap(find.text('August 2026'));
    await tester.pumpAndSettle();
    expect(find.text('August 2026'), findsOneWidget);
    expect(find.text('15 000 000'), findsOneWidget);

    await _scrollTo(tester, find.text('Spent in August'));
  });

  testApp('fresh install shows the empty state', (tester, db) async {
    expect(find.byType(EmptyDashboardCard), findsOneWidget);
    expect(find.text('UZS this month'), findsNWidgets(2));

    await _scrollTo(tester, find.text('Add first transaction'));
    await tester.tap(find.text('Add first transaction'));
    await tester.pumpAndSettle();
    expect(find.byType(AddTransactionPage), findsOneWidget);
  });

  testApp('tapping a recent transaction opens its page', sampleData: true, (
    tester,
    db,
  ) async {
    await _scrollTo(tester, find.text('Korzinka · 13:40'));
    await tester.tap(find.text('Korzinka · 13:40'));
    await tester.pumpAndSettle();
    expect(find.text('Transaction'), findsOneWidget);
    expect(find.bySemanticsLabel('Back'), findsOneWidget);
  });
}
