import '../../../core/time/clock.dart';
import '../../../data/models/month_totals.dart';

/// One month with its changes compared with the month before.
class MonthComparison {
  const MonthComparison({required this.month, this.previous});

  final MonthTotals month;

  /// The month before, or null for the first tracked month.
  final MonthTotals? previous;

  bool get isFirst => previous == null;

  double? get incomeChange => _change(month.income, previous?.income);
  double? get expenseChange => _change(month.expense, previous?.expense);
  double? get savingsChange => _change(month.savings, previous?.savings);

  /// Savings rate change in percentage points.
  double? get rateChange {
    final now = month.savingsRate;
    final before = previous?.savingsRate;
    return now == null || before == null ? null : now - before;
  }

  static double? _change(int now, int? before) => before == null || before == 0
      ? null
      : (now - before) / before.abs() * 100;
}

/// Everything the Monthly overview shows for one year.
class MonthlyOverviewData {
  const MonthlyOverviewData({required this.year, required this.months});

  final int year;

  /// Months of [year] that have transactions, newest first.
  final List<MonthComparison> months;

  bool get isEmpty => months.isEmpty;

  /// The newest month, shown big at the top.
  MonthComparison get latest => months.first;

  /// The other months, newest first.
  List<MonthComparison> get earlier => months.skip(1).toList();

  /// First and last month shown, for "April – September 2026".
  DateTime get firstMonth => months.last.month.month;
  DateTime get lastMonth => months.first.month.month;

  int get income => months.fold(0, (s, m) => s + m.month.income);
  int get expense => months.fold(0, (s, m) => s + m.month.expense);
  int get savings => income - expense;

  /// Mean of the monthly savings rates (months without income are
  /// left out).
  double? get averageRate {
    final rates = months
        .map((m) => m.month.savingsRate)
        .whereType<double>()
        .toList();
    return rates.isEmpty ? null : rates.reduce((a, b) => a + b) / rates.length;
  }

  /// [allMonths] is every month with transactions, oldest first.
  factory MonthlyOverviewData.build(int year, List<MonthTotals> allMonths) {
    final byMonth = {for (final m in allMonths) m.month: m};
    final inYear = allMonths.where((m) => m.month.year == year).toList()
      ..sort((a, b) => b.month.compareTo(a.month));
    return MonthlyOverviewData(
      year: year,
      months: [
        for (final m in inYear)
          MonthComparison(
            month: m,
            previous:
                byMonth[shiftMonths(m.month, -1)] ??
                // A gap (a month with no data) still compares with the
                // latest month before it.
                _latestBefore(allMonths, m.month),
          ),
      ],
    );
  }

  static MonthTotals? _latestBefore(List<MonthTotals> all, DateTime month) {
    MonthTotals? found;
    for (final m in all) {
      if (m.month.isBefore(month)) found = m;
    }
    return found;
  }

  /// Years that have data, newest first. Always includes [currentYear].
  static List<int> years(List<MonthTotals> allMonths, int currentYear) {
    final set = {currentYear, for (final m in allMonths) m.month.year};
    return set.toList()..sort((a, b) => b.compareTo(a));
  }
}
