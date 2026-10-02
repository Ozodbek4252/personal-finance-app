import 'package:drift/drift.dart';

import '../db/app_database.dart';

/// Reads and writes payment methods (Cash, Humo, Uzcard, ...).
class PaymentMethodRepository {
  PaymentMethodRepository(this._db);

  final AppDatabase _db;

  Stream<List<PaymentMethodRow>> watchAll({bool includeArchived = false}) {
    final query = _db.select(_db.paymentMethods)
      ..orderBy([(m) => OrderingTerm.asc(m.sortOrder)]);
    if (!includeArchived) query.where((m) => m.isArchived.equals(false));
    return query.watch();
  }

  /// Adds a custom method at the end of the list. Returns the new id.
  Future<int> addCustom(String name, {String iconKey = 'box'}) async {
    final maxOrder = _db.paymentMethods.sortOrder.max();
    final last = await (_db.selectOnly(
      _db.paymentMethods,
    )..addColumns([maxOrder])).map((row) => row.read(maxOrder)).getSingle();
    return _db
        .into(_db.paymentMethods)
        .insert(
          PaymentMethodsCompanion.insert(
            name: name.trim(),
            iconKey: iconKey,
            isCustom: const Value(true),
            sortOrder: (last ?? -1) + 1,
          ),
        );
  }

  Future<void> rename(int id, String name) async {
    await (_db.update(_db.paymentMethods)..where((m) => m.id.equals(id))).write(
      PaymentMethodsCompanion(name: Value(name.trim())),
    );
  }

  Future<void> setOpeningBalance(int id, int amount) async {
    await (_db.update(_db.paymentMethods)..where((m) => m.id.equals(id))).write(
      PaymentMethodsCompanion(openingBalance: Value(amount)),
    );
  }

  /// Hides a method. Its old transactions keep it.
  Future<void> archive(int id) async {
    await (_db.update(_db.paymentMethods)..where((m) => m.id.equals(id))).write(
      const PaymentMethodsCompanion(isArchived: Value(true)),
    );
  }
}
