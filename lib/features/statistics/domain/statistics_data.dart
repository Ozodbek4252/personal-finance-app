import '../../../data/db/app_database.dart';
import '../../../data/models/transaction_details.dart';
import '../../../data/models/transaction_kind.dart';
import '../../dashboard/domain/dashboard_data.dart';
import 'stat_period.dart';

/// Income and expenses in one period.
class PeriodTotals {
  const PeriodTotals({
    required this.period,
    required this.income,
    required this.expense,
  });

  final StatPeriod period;
  final int income;
  final int expense;

  int get savings => income - expense;

  /// Savings ÷ Income × 100, or null without income.
  double? get savingsRate => income == 0 ? null : savings / income * 100;
}

/// Everything the Statistics screen shows for one selected period.
class StatisticsData {
  const StatisticsData({
    required this.period,
    required this.history,
    required this.categories,
    required this.periodItems,
    required this.historyItems,
  });

  /// How many periods the charts show.
  static const chartLength = 6;

  /// The selected period.
  final StatPeriod period;

  /// The last [chartLength] periods, oldest first; the last one is
  /// [period].
  final List<PeriodTotals> history;

  /// Spending per category in [period], biggest first.
  final List<CategorySpend> categories;

  final List<TransactionDetails> periodItems;
  final List<TransactionDetails> historyItems;

  PeriodTotals get current => history.last;
  PeriodTotals get previous => history[history.length - 2];

  /// Savings rate change vs the previous period, in points.
  double? get savingsRateChange {
    final now = current.savingsRate;
    final before = previous.savingsRate;
    return now == null || before == null ? null : now - before;
  }

  /// Spending change vs the previous period, in percent.
  double? get expenseChange => previous.expense == 0
      ? null
      : (current.expense - previous.expense) / previous.expense * 100;

  /// Average spending over the chart periods.
  int get averageExpense =>
      (history.fold(0, (s, p) => s + p.expense) / history.length).round();

  /// Spending in one category for each chart period, oldest first.
  List<int> categoryHistory(int categoryId) => [
    for (final p in history)
      historyItems
          .where(
            (t) =>
                t.kind == TransactionKind.expense &&
                t.category.id == categoryId &&
                p.period.contains(t.occurredAt),
          )
          .fold(0, (s, t) => s + t.transaction.amount),
  ];

  /// Number of transactions in one category in the selected period.
  int categoryCount(int categoryId) =>
      periodItems.where((t) => t.category.id == categoryId).length;

  /// Expense categories that have spending in any chart period, in the
  /// user's category order.
  List<CategoryRow> trendCategories(List<CategoryRow> ordered) {
    final used = {
      for (final t in historyItems)
        if (t.kind == TransactionKind.expense) t.category.id,
    };
    return [
      for (final c in ordered)
        if (used.contains(c.id)) c,
    ];
  }

  /// [items] must cover all chart periods (see [StatPeriod.lastN]).
  factory StatisticsData.build(
    StatPeriod period,
    List<TransactionDetails> items,
  ) {
    final periods = period.lastN(chartLength);
    final history = [
      for (final p in periods)
        _totals(p, items.where((t) => p.contains(t.occurredAt))),
    ];
    final periodItems = items.where((t) => period.contains(t.occurredAt));
    return StatisticsData(
      period: period,
      history: history,
      categories: DashboardData.spendByCategory(periodItems.toList()),
      periodItems: periodItems.toList(),
      historyItems: items,
    );
  }

  static PeriodTotals _totals(
    StatPeriod p,
    Iterable<TransactionDetails> items,
  ) {
    var income = 0;
    var expense = 0;
    for (final t in items) {
      if (t.kind == TransactionKind.income) {
        income += t.transaction.amount;
      } else {
        expense += t.transaction.amount;
      }
    }
    return PeriodTotals(period: p, income: income, expense: expense);
  }
}

/// Round axis steps for charts: 1, 2 or 5 × 10^n.
double niceStep(double rough) {
  if (rough <= 0) return 1;
  var magnitude = 1.0;
  while (magnitude * 10 <= rough) {
    magnitude *= 10;
  }
  while (magnitude > rough) {
    magnitude /= 10;
  }
  for (final m in [1, 2, 5, 10]) {
    if (m * magnitude >= rough) return m * magnitude;
  }
  return 10 * magnitude;
}
