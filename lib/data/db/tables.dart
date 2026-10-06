import 'package:drift/drift.dart';

import '../models/currency.dart';
import '../models/transaction_kind.dart';

/// Expense and income categories, like "Groceries" or "Salary".
@DataClassName('CategoryRow')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 40)();
  TextColumn get kind => textEnum<TransactionKind>()();

  /// Key in `AppIcons.categoryIcons`, like "cart".
  TextColumn get iconKey => text()();

  /// Name of a `CategoryColor` value, like "green".
  TextColumn get colorKey => text()();

  /// Order in lists. The first 9 expense categories are the
  /// "quick add" tiles on the add screen.
  IntColumn get sortOrder => integer()();

  /// Hidden from pickers, but old transactions keep their category.
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
}

/// Where money is paid from or received to, like "Humo" or "Cash".
@DataClassName('PaymentMethodRow')
class PaymentMethods extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 40)();

  /// Key in `AppIcons.all`, like "card" or "cash".
  TextColumn get iconKey => text()();

  /// True for methods the user added (shown with a "Custom" label).
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer()();

  /// Money that was already there before the first transaction, in the
  /// smallest unit of [currency] (so'm or cents).
  IntColumn get openingBalance => integer().withDefault(const Constant(0))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  /// Money on this method is in this currency. Added in schema 2.
  TextColumn get currency =>
      textEnum<Currency>().withDefault(const Constant('uzs'))();
}

/// One expense or income.
@DataClassName('TransactionRow')
// Lists and month totals read transactions by date.
@TableIndex(name: 'transactions_occurred_at', columns: {#occurredAt})
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kind => textEnum<TransactionKind>()();

  /// Whole UZS, always positive. [kind] says if it is in or out.
  // ignore: recursive_getters (drift reads the column inside its own check)
  IntColumn get amount => integer().check(amount.isBiggerThanValue(0))();
  IntColumn get categoryId => integer().references(Categories, #id)();
  IntColumn get paymentMethodId => integer().references(PaymentMethods, #id)();

  /// When the money was spent or received (local time).
  DateTimeColumn get occurredAt => dateTime()();

  /// Short text shown in lists, like "Korzinka" or "Taxi · Yandex Go".
  TextColumn get note => text().nullable()();

  /// Longer optional text, shown on the details screen.
  TextColumn get description => text().nullable()();

  /// Path to a receipt photo on the device.
  TextColumn get receiptPath => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// Money moved from one payment method to another in a different
/// currency, like 1 265 000 UZS from Humo to $100 in Cash (USD).
///
/// Exchanges are not income or expenses. They only move money between
/// balances. Added in schema 2.
@DataClassName('ExchangeRow')
@TableIndex(name: 'exchanges_occurred_at', columns: {#occurredAt})
class Exchanges extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The method the money leaves.
  IntColumn get fromMethodId => integer().references(PaymentMethods, #id)();

  /// Amount that leaves, in the smallest unit of the "from" currency.
  IntColumn get fromAmount =>
      // ignore: recursive_getters (drift reads the column in its own check)
      integer().check(fromAmount.isBiggerThanValue(0))();

  /// The method the money arrives at.
  IntColumn get toMethodId => integer().references(PaymentMethods, #id)();

  /// Amount that arrives, in the smallest unit of the "to" currency.
  // ignore: recursive_getters (drift reads the column inside its own check)
  IntColumn get toAmount => integer().check(toAmount.isBiggerThanValue(0))();

  /// UZS for 1 USD at the time of the exchange. Kept, so old exchanges
  /// never change when the rate changes.
  RealColumn get rate => real()();

  /// Extra cost taken from the "from" method, in its smallest unit.
  IntColumn get fee => integer().withDefault(const Constant(0))();

  /// When the exchange happened (local time).
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get note => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// Official rates from the Central Bank (CBU), one per currency and day.
/// The last one is used when there is no internet. Added in schema 2.
@DataClassName('ExchangeRateRow')
class ExchangeRates extends Table {
  TextColumn get currency => textEnum<Currency>()();

  /// The day the rate is for (local midnight).
  DateTimeColumn get day => dateTime()();

  /// UZS for 1 unit of [currency].
  RealColumn get rate => real()();

  @override
  Set<Column> get primaryKey => {currency, day};
}

/// Simple key-value store for app settings, like the theme mode.
@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
