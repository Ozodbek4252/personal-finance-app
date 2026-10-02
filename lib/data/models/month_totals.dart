/// Income and expenses for one calendar month.
class MonthTotals {
  const MonthTotals({
    required this.month,
    required this.income,
    required this.expense,
  });

  /// First day of the month, at midnight.
  final DateTime month;
  final int income;
  final int expense;

  /// Income − Expenses. Can be negative.
  int get savings => income - expense;

  /// Savings ÷ Income × 100. Null when there is no income.
  double? get savingsRate => income == 0 ? null : savings / income * 100;

  @override
  bool operator ==(Object other) =>
      other is MonthTotals &&
      other.month == month &&
      other.income == income &&
      other.expense == expense;

  @override
  int get hashCode => Object.hash(month, income, expense);

  @override
  String toString() => 'MonthTotals($month, in: $income, out: $expense)';
}
