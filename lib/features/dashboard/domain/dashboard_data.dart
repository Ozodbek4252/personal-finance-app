import '../../../core/format/date_format.dart';
import '../../../core/format/money_format.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/time/clock.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/db/app_database.dart';
import '../../../data/models/display_style.dart';
import '../../../data/models/month_totals.dart';
import '../../../data/models/transaction_details.dart';
import '../../../data/models/transaction_kind.dart';

/// How much was spent in one category in a month.
class CategorySpend {
  const CategorySpend({
    required this.category,
    required this.amount,
    required this.percent,
  });

  final CategoryRow category;
  final int amount;

  /// Share of all spending in the month, 0–100.
  final double percent;
}

/// One part of an insight sentence. Bold parts carry the key number.
typedef InsightSpan = ({String text, bool bold});

/// A short sentence about the month, like
/// "**Groceries** are your largest expense category…".
class Insight {
  const Insight({required this.icon, required this.spans, this.color});

  final AppIconData icon;

  /// Category color of the icon tile. Null means the savings style.
  final CategoryColor? color;
  final List<InsightSpan> spans;

  String get plainText => spans.map((s) => s.text).join();
}

/// Everything the Dashboard shows for the selected month,
/// except the balance and the recent list.
class DashboardData {
  const DashboardData({
    required this.month,
    required this.current,
    required this.previous,
    required this.categories,
    required this.trend,
    required this.insights,
    required this.hasAnyTransactions,
  });

  /// First day of the selected month.
  final DateTime month;
  final MonthTotals current;

  /// The month before, or null if nothing was recorded then.
  final MonthTotals? previous;

  /// Spending per category, biggest first.
  final List<CategorySpend> categories;

  /// Six months ending with [month], oldest first. Empty months are 0.
  final List<MonthTotals> trend;
  final List<Insight> insights;

  /// False on a fresh install. Then the Dashboard shows its empty state.
  final bool hasAnyTransactions;

  /// Change in percent vs the previous month, or null if not comparable.
  double? get incomeChange => _change(current.income, previous?.income);
  double? get expenseChange => _change(current.expense, previous?.expense);

  /// Savings rate change in percentage points.
  double? get savingsRateChange {
    final now = current.savingsRate;
    final before = previous?.savingsRate;
    return now == null || before == null ? null : now - before;
  }

  static DashboardData build({
    required DateTime month,
    required List<TransactionDetails> monthTransactions,
    required List<TransactionDetails> previousTransactions,
    required List<MonthTotals> allMonths,
  }) {
    final byMonth = {for (final m in allMonths) m.month: m};
    final prevMonth = shiftMonths(month, -1);
    final current =
        byMonth[month] ?? MonthTotals(month: month, income: 0, expense: 0);
    final previous = byMonth[prevMonth];

    final categories = spendByCategory(monthTransactions);
    final previousCategories = spendByCategory(previousTransactions);

    final trend = [
      for (var i = 5; i >= 0; i--)
        byMonth[shiftMonths(month, -i)] ??
            MonthTotals(month: shiftMonths(month, -i), income: 0, expense: 0),
    ];

    return DashboardData(
      month: month,
      current: current,
      previous: previous,
      categories: categories,
      trend: trend,
      hasAnyTransactions: allMonths.isNotEmpty,
      insights: [
        ?_largestCategoryInsight(categories),
        ?_categoryChangeInsight(categories, previousCategories, prevMonth),
        ?_savingsInsight(current, allMonths),
      ],
    );
  }

  /// Totals of expenses per category, biggest first.
  static List<CategorySpend> spendByCategory(
    List<TransactionDetails> transactions,
  ) {
    final sums = <int, (CategoryRow, int)>{};
    var total = 0;
    for (final t in transactions) {
      if (t.kind != TransactionKind.expense) continue;
      final amount = t.transaction.amount;
      final (_, sum) = sums[t.category.id] ?? (t.category, 0);
      sums[t.category.id] = (t.category, sum + amount);
      total += amount;
    }
    final list = [
      for (final (category, amount) in sums.values)
        CategorySpend(
          category: category,
          amount: amount,
          percent: amount / total * 100,
        ),
    ]..sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }

  static double? _change(int now, int? before) =>
      before == null || before == 0 ? null : (now - before) / before * 100;

  /// "Groceries are your largest expense category this month, at 27%…"
  static Insight? _largestCategoryInsight(List<CategorySpend> categories) {
    if (categories.length < 2) return null;
    final top = categories.first;
    // "Groceries are", "Transportation is".
    final verb = top.category.name.endsWith('s') ? 'are' : 'is';
    return Insight(
      icon: top.category.icon,
      color: top.category.color,
      spans: [
        (text: top.category.name, bold: true),
        (
          text:
              ' $verb your largest expense category this month, at '
              '${top.percent.round()}% of spending.',
          bold: false,
        ),
      ],
    );
  }

  /// "You spent 18% more on transportation than in August."
  /// Picks the biggest rise; if nothing rose, the biggest drop.
  static Insight? _categoryChangeInsight(
    List<CategorySpend> now,
    List<CategorySpend> before,
    DateTime previousMonth,
  ) {
    final beforeById = {for (final c in before) c.category.id: c.amount};
    CategorySpend? pick;
    double? pickChange;
    for (final c in now) {
      final old = beforeById[c.category.id];
      if (old == null || old == 0) continue;
      final change = (c.amount - old) / old * 100;
      if (change.round() == 0) continue;
      final better =
          pickChange == null ||
          (change > 0 && (pickChange < 0 || change > pickChange)) ||
          (change < 0 && pickChange < 0 && change < pickChange);
      if (better) {
        pick = c;
        pickChange = change;
      }
    }
    if (pick == null || pickChange == null) return null;
    final word = pickChange > 0 ? 'more' : 'less';
    return Insight(
      icon: pick.category.icon,
      color: pick.category.color,
      spans: [
        (text: 'You spent ', bold: false),
        (text: '${pickChange.abs().round()}% $word', bold: true),
        (
          text:
              ' on ${pick.category.name.toLowerCase()} than in '
              '${DateText.month(previousMonth)}.',
          bold: false,
        ),
      ],
    );
  }

  /// "You saved 12 450 000 UZS this month — your best month since April."
  static Insight? _savingsInsight(
    MonthTotals current,
    List<MonthTotals> allMonths,
  ) {
    if (current.income == 0 && current.expense == 0) return null;
    if (current.savings < 0) {
      return Insight(
        icon: AppIcons.coins,
        spans: [
          (text: 'You spent ', bold: false),
          (text: MoneyFormat.withCurrency(-current.savings), bold: true),
          (text: ' more than you earned this month.', bold: false),
        ],
      );
    }

    final earlier = allMonths.where((m) => m.month.isBefore(current.month));
    String suffix = '.';
    if (earlier.isNotEmpty) {
      // The newest earlier month that saved at least as much.
      final beaten = earlier.toList().reversed.where(
        (m) => m.savings >= current.savings,
      );
      if (beaten.isEmpty) {
        // Better than every month: "since <first tracked month>".
        suffix =
            ' — your best month since ${DateText.month(earlier.first.month)}.';
      } else if (beaten.first.month != shiftMonths(current.month, -1)) {
        final last = beaten.first.month;
        final after = shiftMonths(last, 1);
        suffix = ' — your best month since ${DateText.month(after)}.';
      }
    }
    return Insight(
      icon: AppIcons.coins,
      spans: [
        (text: 'You saved ', bold: false),
        (text: MoneyFormat.withCurrency(current.savings), bold: true),
        (text: ' this month$suffix', bold: false),
      ],
    );
  }
}
