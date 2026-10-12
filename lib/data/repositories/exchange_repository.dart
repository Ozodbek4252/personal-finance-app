import 'package:drift/drift.dart';

import '../../core/time/clock.dart';
import '../db/app_database.dart';
import '../db/exchange_fees.dart';
import '../models/exchange_details.dart';

/// Reads and writes exchanges between so'm and dollar methods.
class ExchangeRepository {
  ExchangeRepository(this._db, this._clock);

  final AppDatabase _db;
  final Clock _clock;

  late final _from = _db.alias(_db.paymentMethods, 'from_method');
  late final _to = _db.alias(_db.paymentMethods, 'to_method');

  /// All exchanges, newest first.
  Stream<List<ExchangeDetails>> watchAll() =>
      _joined().watch().map((rows) => rows.map(_toDetails).toList());

  /// Like [watchAll], but reads once.
  Future<List<ExchangeDetails>> getAll() =>
      _joined().get().then((rows) => rows.map(_toDetails).toList());

  /// Exchanges from [from] (included) to [to] (not included),
  /// newest first.
  Stream<List<ExchangeDetails>> watchBetween(DateTime from, DateTime to) {
    final e = _db.exchanges;
    final query = _joined()
      ..where(
        e.occurredAt.isBiggerOrEqualValue(from) &
            e.occurredAt.isSmallerThanValue(to),
      );
    return query.watch().map((rows) => rows.map(_toDetails).toList());
  }

  /// One exchange, or null after it is deleted.
  Stream<ExchangeDetails?> watchById(int id) {
    final query = _joined()..where(_db.exchanges.id.equals(id));
    return query.watchSingleOrNull().map(
      (row) => row == null ? null : _toDetails(row),
    );
  }

  /// Saves a new exchange and returns its id. A so'm fee is also saved
  /// as an expense.
  Future<int> add(ExchangeDraft draft) {
    final now = _clock.now();
    return _db.transaction(() async {
      final id = await _db
          .into(_db.exchanges)
          .insert(
            _companion(
              draft,
            ).copyWith(createdAt: Value(now), updatedAt: Value(now)),
          );
      await syncFeeExpense(_db, id);
      return id;
    });
  }

  Future<void> update(int id, ExchangeDraft draft) => _db.transaction(() async {
    await (_db.update(_db.exchanges)..where((e) => e.id.equals(id))).write(
      _companion(draft).copyWith(updatedAt: Value(_clock.now())),
    );
    await syncFeeExpense(_db, id);
  });

  /// Deletes the exchange and its fee expense.
  Future<void> delete(int id) => _db.transaction(() async {
    await deleteFeeExpense(_db, id);
    await (_db.delete(_db.exchanges)..where((e) => e.id.equals(id))).go();
  });

  /// Puts a deleted exchange back exactly as it was (same id), with its
  /// fee expense. Used by "Undo" after a delete.
  Future<void> restore(ExchangeRow row) => _db.transaction(() async {
    await _db.into(_db.exchanges).insert(row, mode: InsertMode.insertOrReplace);
    await syncFeeExpense(_db, row.id);
  });

  JoinedSelectStatement<HasResultSet, dynamic> _joined() {
    final e = _db.exchanges;
    return _db.select(e).join([
      innerJoin(_from, _from.id.equalsExp(e.fromMethodId)),
      innerJoin(_to, _to.id.equalsExp(e.toMethodId)),
    ])..orderBy([OrderingTerm.desc(e.occurredAt), OrderingTerm.desc(e.id)]);
  }

  ExchangeDetails _toDetails(TypedResult row) => ExchangeDetails(
    exchange: row.readTable(_db.exchanges),
    from: row.readTable(_from),
    to: row.readTable(_to),
  );

  ExchangesCompanion _companion(ExchangeDraft d) => ExchangesCompanion(
    fromMethodId: Value(d.fromMethodId),
    fromAmount: Value(d.fromAmount),
    toMethodId: Value(d.toMethodId),
    toAmount: Value(d.toAmount),
    rate: Value(d.rate),
    fee: Value(d.fee),
    occurredAt: Value(d.occurredAt),
    note: Value(
      d.note == null || d.note!.trim().isEmpty ? null : d.note!.trim(),
    ),
  );
}
