import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../models/transaction_kind.dart';

/// Reads and writes expense and income categories.
class CategoryRepository {
  CategoryRepository(this._db);

  final AppDatabase _db;

  /// Categories in the user's order. Archived ones are left out
  /// unless [includeArchived] is true.
  Stream<List<CategoryRow>> watchAll({
    TransactionKind? kind,
    bool includeArchived = false,
  }) {
    final query = _db.select(_db.categories)
      ..where((c) {
        Expression<bool> e = const Constant(true);
        if (kind != null) e = e & c.kind.equalsValue(kind);
        if (!includeArchived) e = e & c.isArchived.equals(false);
        return e;
      })
      ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]);
    return query.watch();
  }

  /// One category (archived ones too), or null if it does not exist.
  Future<CategoryRow?> getById(int id) => (_db.select(
    _db.categories,
  )..where((c) => c.id.equals(id))).getSingleOrNull();

  /// Adds a category at the end of its list. Returns the new id.
  Future<int> add({
    required String name,
    required TransactionKind kind,
    required String iconKey,
    required String colorKey,
  }) async {
    final maxOrder = _db.categories.sortOrder.max();
    final last =
        await (_db.selectOnly(_db.categories)
              ..addColumns([maxOrder])
              ..where(_db.categories.kind.equalsValue(kind)))
            .map((row) => row.read(maxOrder))
            .getSingle();
    return _db
        .into(_db.categories)
        .insert(
          CategoriesCompanion.insert(
            name: name.trim(),
            kind: kind,
            iconKey: iconKey,
            colorKey: colorKey,
            sortOrder: (last ?? -1) + 1,
          ),
        );
  }

  Future<void> update(
    int id, {
    String? name,
    String? iconKey,
    String? colorKey,
  }) async {
    await (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(
        name: name == null ? const Value.absent() : Value(name.trim()),
        iconKey: Value.absentIfNull(iconKey),
        colorKey: Value.absentIfNull(colorKey),
      ),
    );
  }

  /// Saves a new order. [idsInOrder] lists category ids from first to last.
  Future<void> reorder(List<int> idsInOrder) {
    return _db.batch((b) {
      for (final (i, id) in idsInOrder.indexed) {
        b.update(
          _db.categories,
          CategoriesCompanion(sortOrder: Value(i)),
          where: (c) => c.id.equals(id),
        );
      }
    });
  }

  /// Hides a category. Its old transactions keep it.
  Future<void> archive(int id) async {
    await (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(
      const CategoriesCompanion(isArchived: Value(true)),
    );
  }
}
