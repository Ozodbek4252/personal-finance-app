/// Money going out (expense) or coming in (income).
///
/// Stored by name in the database, so do not rename the values.
enum TransactionKind {
  expense,
  income;

  /// +1 for income, −1 for expense. Multiply an amount by it to get
  /// its effect on the balance.
  int get sign => this == income ? 1 : -1;
}
