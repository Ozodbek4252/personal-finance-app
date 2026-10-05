import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/core/time/clock.dart';
import 'package:personal_finance/data/db/app_database.dart';
import 'package:personal_finance/data/db/seed.dart';
import 'package:personal_finance/data/repositories/transaction_repository.dart';
import 'package:personal_finance/features/statistics/domain/stat_period.dart';
import 'package:personal_finance/features/statistics/domain/statistics_data.dart';

import '../../helpers/test_db.dart';

void main() {
  group('StatPeriod', () {
    final wed = DateTime(2026, 9, 30, 15);

    test('weeks start on Monday and can cross months', () {
      final week = StatPeriod.containing(PeriodUnit.week, wed);
      expect(week.start, DateTime(2026, 9, 28));
      expect(week.end, DateTime(2026, 10, 5));
      expect(week.title, '28 Sep – 4 Oct 2026');
      expect(week.previous.shortLabel, '21 Sep');
      expect(week.previous.asPrevious, 'last week');
    });

    test('months and years', () {
      final month = StatPeriod.containing(PeriodUnit.month, wed);
      expect(month.title, 'September 2026');
      expect(month.previous.asPrevious, 'August');
      expect(month.lastN(6).map((p) => p.shortLabel), [
        'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', //
      ]);
      final year = StatPeriod.containing(PeriodUnit.year, wed);
      expect(year.title, '2026');
      expect(year.contains(DateTime(2026, 12, 31, 23, 59)), isTrue);
      expect(year.contains(DateTime(2027)), isFalse);
    });

    test('a month that crosses a year end', () {
      final jan = StatPeriod.containing(PeriodUnit.month, DateTime(2027, 1, 5));
      expect(jan.previous.title, 'December 2026');
    });
  });

  test('niceStep picks 1, 2 or 5 × 10^n', () {
    expect(niceStep(15500000 / 4), 5000000);
    expect(niceStep(800000), 1000000);
    expect(niceStep(150), 200);
    expect(niceStep(0), 1);
  });

  group('StatisticsData on the sample data', () {
    late AppDatabase db;
    late StatisticsData data;

    setUpAll(() async {
      db = memoryDb();
      await ensureDefaults(db);
      await seedSampleData(db);
      final sept = StatPeriod.containing(
        PeriodUnit.month,
        DateTime(2026, 9, 30),
      );
      final items = await TransactionRepository(
        db,
        const SystemClock(),
      ).watchBetween(sept.lastN(6).first.start, sept.end).first;
      data = StatisticsData.build(sept, items);
    });
    tearDownAll(() => db.close());

    test('savings card numbers match the board', () {
      expect(data.current.income, 15500000);
      expect(data.current.expense, 3050000);
      expect(data.current.savings, 12450000);
      expect(data.current.savingsRate!.toStringAsFixed(1), '80.3');
      expect(data.previous.savingsRate!.toStringAsFixed(1), '71.5');
    });

    test('charts match the board', () {
      expect(data.categories, hasLength(7));
      expect(data.history.map((p) => p.income), [
        14000000, 14000000, 15200000, 14500000, 15000000, 15500000, //
      ]);
      expect(data.expenseChange!.toStringAsFixed(1), '-28.7');
      expect(data.averageExpense, 3846667, reason: '"3 847 000" rounded');
    });

    test('category trend matches the board', () {
      final transport = data.categories
          .firstWhere((c) => c.category.name == 'Transportation')
          .category;
      expect(data.categoryHistory(transport.id), [
        290000, 320000, 365000, 300000, 347000, 410000, //
      ]);
      expect(data.categoryCount(transport.id), 14);
    });
  });
}
