import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/core/time/clock.dart';
import 'package:personal_finance/data/db/app_database.dart';
import 'package:personal_finance/data/db/seed.dart';
import 'package:personal_finance/data/models/month_totals.dart';
import 'package:personal_finance/data/repositories/transaction_repository.dart';
import 'package:personal_finance/features/dashboard/domain/dashboard_data.dart';

import '../../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late TransactionRepository repo;

  setUp(() async {
    db = memoryDb();
    repo = TransactionRepository(db, const SystemClock());
    await ensureDefaults(db);
    await seedSampleData(db);
  });
  tearDown(() => db.close());

  Future<DashboardData> build(DateTime month) async => DashboardData.build(
    month: month,
    monthTransactions: await repo
        .watchBetween(month, nextMonthStart(month))
        .first,
    previousTransactions: await repo
        .watchBetween(DateTime(month.year, month.month - 1), month)
        .first,
    allMonths: await repo.watchMonthTotals().first,
  );

  test('September matches the Dashboard board', () async {
    final data = await build(DateTime(2026, 9));

    expect(data.current.income, 15500000);
    expect(data.current.expense, 3050000);
    expect(data.incomeChange!.toStringAsFixed(1), '3.3');
    expect(data.expenseChange!.toStringAsFixed(1), '-28.7');
    expect(data.current.savingsRate!.round(), 80);

    expect(
      [
        for (final c in data.categories.take(4))
          (c.category.name, c.percent.round(), c.amount),
      ],
      [
        ('Groceries', 27, 820000),
        ('Emergency', 16, 500000),
        ('Shopping', 15, 470000),
        ('Transportation', 13, 410000),
      ],
    );
    final rest = data.categories.skip(4).fold(0, (s, c) => s + c.amount);
    expect(rest, 850000, reason: '"3 more categories · 850 000 UZS"');

    expect(data.trend.map((m) => m.expense), [
      3480000, 3720000, 4650000, 3900000, 4280000, 3050000, //
    ]);
  });

  test('insights match the board', () async {
    final data = await build(DateTime(2026, 9));
    expect(data.insights.map((i) => i.plainText), [
      'Groceries are your largest expense category this month, '
          'at 27% of spending.',
      'You spent 18% more on transportation than in August.',
      'You saved 12 450 000 UZS this month '
          '— your best month since April.',
    ]);
  });

  test('a month with no data before it has no comparisons', () async {
    final data = await build(DateTime(2026, 4));
    expect(data.previous, isNull);
    expect(data.incomeChange, isNull);
    expect(data.savingsRateChange, isNull);
    expect(data.insights.last.plainText, endsWith('this month.'));
  });

  test('empty database shows the empty state', () {
    final data = DashboardData.build(
      month: DateTime(2026, 9),
      monthTransactions: const [],
      previousTransactions: const [],
      allMonths: const [],
    );
    expect(data.hasAnyTransactions, isFalse);
    expect(data.insights, isEmpty);
    expect(data.trend, hasLength(6));
  });

  test('spending more than earning gives a warning insight', () {
    final data = DashboardData.build(
      month: DateTime(2026, 9),
      monthTransactions: const [],
      previousTransactions: const [],
      allMonths: [
        MonthTotals(month: DateTime(2026, 9), income: 1000, expense: 3000),
      ],
    );
    expect(
      data.insights.single.plainText,
      'You spent 2 000 UZS more than you earned this month.',
    );
  });
}
