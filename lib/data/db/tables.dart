import 'package:drift/drift.dart';

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

  /// Money that was already there before the first transaction, in UZS.
  IntColumn get openingBalance => integer().withDefault(const Constant(0))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
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

/// Simple key-value store for app settings, like the theme mode.
@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
