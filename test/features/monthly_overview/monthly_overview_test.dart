import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/core/time/clock.dart';
import 'package:personal_finance/data/db/app_database.dart';
import 'package:personal_finance/data/db/seed.dart';
import 'package:personal_finance/data/models/month_totals.dart';
import 'package:personal_finance/data/repositories/transaction_repository.dart';
import 'package:personal_finance/features/monthly_overview/domain/monthly_overview_data.dart';
import 'package:personal_finance/features/monthly_overview/ui/monthly_overview_page.dart';

import '../../helpers/test_db.dart';

void main() {
  group('MonthlyOverviewData on the sample data', () {
    late AppDatabase db;
    late List<MonthTotals> all;

    setUpAll(() async {
      db = memoryDb();
      await ensureDefaults(db);
      await seedSampleData(db);
      all = await TransactionRepository(
        db,
        const SystemClock(),
      ).watchMonthTotals().first;
    });
    tearDownAll(() => db.close());

    test('summary matches the board', () {
      final data = MonthlyOverviewData.build(2026, all);
      expect(data.firstMonth, DateTime(2026, 4));
      expect(data.lastMonth, DateTime(2026, 9));
      expect(data.income, 88200000);
      expect(data.expense, 23080000);
      expect(data.savings, 65120000);
      expect(data.averageRate!.toStringAsFixed(1), '73.8');
    });

    test('latest month changes match the board', () {
      final sept = MonthlyOverviewData.build(2026, all).latest;
      expect(sept.incomeChange!.toStringAsFixed(1), '3.3');
      expect(sept.expenseChange!.toStringAsFixed(1), '-28.7');
      expect(sept.savingsChange!.toStringAsFixed(1), '16.1');
      expect(sept.rateChange!.toStringAsFixed(1), '8.9');
    });

    test('earlier months match the board', () {
      final earlier = MonthlyOverviewData.build(2026, all).earlier;
      expect(earlier.map((m) => m.month.month.month), [8, 7, 6, 5, 4]);
      final aug = earlier.first;
      expect(aug.incomeChange!.toStringAsFixed(1), '3.4');
      expect(aug.expenseChange!.toStringAsFixed(1), '9.7');
      expect(aug.savingsChange!.toStringAsFixed(1), '1.1');
      expect(aug.rateChange!.toStringAsFixed(1), '-1.6');
      expect(earlier.last.isFirst, isTrue, reason: 'April is the first month');
    });

    test('years and an empty year', () {
      expect(MonthlyOverviewData.years(all, 2027), [2027, 2026]);
      expect(MonthlyOverviewData.build(2025, all).isEmpty, isTrue);
    });
  });

  testApp('page shows the year like the design', sampleData: true, (
    tester,
    db,
  ) async {
    await tester.tap(find.bySemanticsLabel('Statistics'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Monthly overview'));
    await tester.pumpAndSettle();

    expect(find.byType(MonthlyOverviewPage), findsOneWidget);
    expect(find.text('APRIL – SEPTEMBER 2026'), findsOneWidget);
    expect(find.text('88 200 000'), findsOneWidget);
    expect(find.text('73.8%'), findsOneWidget);
    expect(find.text('vs August'), findsOneWidget);
    expect(find.text('+16.1%'), findsOneWidget);
    expect(find.text('+8.9 pts'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('First tracked month'), 400);
    expect(find.text('75.1% saved'), findsOneWidget);
  });

  testApp('year picker switches to an empty year', sampleData: true, (
    tester,
    db,
  ) async {
    final context = tester.element(find.byType(Scaffold).first);
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const MonthlyOverviewPage()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Year 2026'));
    await tester.pumpAndSettle();
    expect(find.text('Year'), findsOneWidget);
    // Only 2026 has data and it is the current year.
    expect(find.text('2026'), findsWidgets);
  });
}
