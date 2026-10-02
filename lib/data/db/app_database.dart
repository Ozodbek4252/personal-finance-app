import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../models/transaction_kind.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Categories, PaymentMethods, Transactions, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// The real database file on the device.
  factory AppDatabase.onDevice() =>
      AppDatabase(driftDatabase(name: 'personal_finance'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
