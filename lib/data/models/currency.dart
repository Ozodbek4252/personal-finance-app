/// Currencies the app knows. UZS is the main one: totals and statistics
/// are counted in so'm. USD is kept as savings.
///
/// Stored by name in the database, so do not rename the values.
enum Currency {
  uzs('UZS', 1),
  usd('USD', 100);

  const Currency(this.code, this.minorUnits);

  /// Code shown next to amounts, like "UZS".
  final String code;

  /// How many stored units make one whole unit. Amounts are stored as
  /// ints in the smallest unit: whole so'm for UZS, cents for USD.
  final int minorUnits;
}
