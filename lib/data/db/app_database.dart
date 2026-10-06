import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../models/currency.dart';
import '../models/transaction_kind.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Categories,
    PaymentMethods,
    Transactions,
    Settings,
    Exchanges,
    ExchangeRates,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// The real database file on the device.
  factory AppDatabase.onDevice() =>
      AppDatabase(driftDatabase(name: 'personal_finance'));

  /// 1: first release.
  /// 2: payment method currency, exchanges and exchange rates.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // Only add things here. Real user data lives in this database,
      // so never drop or rewrite old tables.
      if (from < 2) {
        await m.addColumn(paymentMethods, paymentMethods.currency);
        await m.createTable(exchanges);
        await m.createIndex(exchangesOccurredAt);
        await m.createTable(exchangeRates);
        // New installs get a dollar cash method from the defaults.
        // Give old installs the same one.
        await customStatement(
          'INSERT INTO payment_methods '
          '(name, icon_key, is_custom, sort_order, currency) '
          "SELECT 'Cash (USD)', 'cash', 0, MAX(sort_order) + 1, 'usd' "
          'FROM payment_methods HAVING COUNT(*) > 0',
        );
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
