import 'package:drift/drift.dart';

import '../../core/time/clock.dart';
import '../db/app_database.dart';
import '../models/month_totals.dart';
import '../models/transaction_details.dart';
import '../models/transaction_kind.dart';

/// Reads and writes transactions. All "watch" methods return streams
/// that emit again whenever the data changes.
class TransactionRepository {
  TransactionRepository(this._db, this._clock);

  final AppDatabase _db;
  final Clock _clock;

  /// Transactions from [from] (included) to [to] (not included),
  /// newest first.
  Stream<List<TransactionDetails>> watchBetween(DateTime from, DateTime to) {
    final t = _db.transactions;
    final query = _joined()
      ..where(
        t.occurredAt.isBiggerOrEqualValue(from) &
            t.occurredAt.isSmallerThanValue(to),
      );
    return query.watch().map((rows) => rows.map(_toDetails).toList());
  }

  /// The newest [limit] transactions.
  Stream<List<TransactionDetails>> watchRecent({int limit = 4}) {
    final query = _joined()..limit(limit);
    return query.watch().map((rows) => rows.map(_toDetails).toList());
  }

  /// One transaction, or null after it is deleted.
  Stream<TransactionDetails?> watchById(int id) {
    final query = _joined()..where(_db.transactions.id.equals(id));
    return query.watchSingleOrNull().map(
      (row) => row == null ? null : _toDetails(row),
    );
  }

  /// Income and expense totals for every month that has transactions,
  /// oldest month first.
  Stream<List<MonthTotals>> watchMonthTotals() {
    final t = _db.transactions;
    final query = _db.selectOnly(t)
      ..addColumns([t.kind, t.amount, t.occurredAt]);
    return query.watch().map((rows) {
      final income = <DateTime, int>{};
      final expense = <DateTime, int>{};
      for (final row in rows) {
        final month = monthStart(row.read(t.occurredAt)!);
        final amount = row.read(t.amount)!;
        final kind = t.kind.converter.fromSql(row.read(t.kind)!);
        final bucket = kind == TransactionKind.income ? income : expense;
        bucket[month] = (bucket[month] ?? 0) + amount;
      }
      final months = {...income.keys, ...expense.keys}.toList()..sort();
      return [
        for (final m in months)
          MonthTotals(
            month: m,
            income: income[m] ?? 0,
            expense: expense[m] ?? 0,
          ),
      ];
    });
  }

  /// Current balance of every payment method, by method id:
  /// opening balance + all income − all expenses.
  Stream<Map<int, int>> watchBalances() {
    final query = _db.customSelect(
      'SELECT pm.id AS id, pm.opening_balance + COALESCE(SUM('
      "CASE WHEN t.kind = 'income' THEN t.amount ELSE -t.amount END"
      '), 0) AS balance '
      'FROM payment_methods pm '
      'LEFT JOIN transactions t ON t.payment_method_id = pm.id '
      'GROUP BY pm.id',
      readsFrom: {_db.paymentMethods, _db.transactions},
    );
    return query.watch().map(
      (rows) => {
        for (final row in rows) row.read<int>('id'): row.read<int>('balance'),
      },
    );
  }

  /// Saves a new transaction and returns its id.
  Future<int> add(TransactionDraft draft) {
    final now = _clock.now();
    return _db
        .into(_db.transactions)
        .insert(
          _companion(
            draft,
          ).copyWith(createdAt: Value(now), updatedAt: Value(now)),
        );
  }

  Future<void> update(int id, TransactionDraft draft) async {
    await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
      _companion(draft).copyWith(updatedAt: Value(_clock.now())),
    );
  }

  Future<void> delete(int id) async {
    await (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();
  }

  /// Copies a transaction with the current date and time.
  /// Returns the new id.
  Future<int> duplicate(int id) async {
    final row = await (_db.select(
      _db.transactions,
    )..where((t) => t.id.equals(id))).getSingle();
    return add(
      TransactionDraft(
        kind: row.kind,
        amount: row.amount,
        categoryId: row.categoryId,
        paymentMethodId: row.paymentMethodId,
        occurredAt: _clock.now(),
        note: row.note,
        description: row.description,
        receiptPath: row.receiptPath,
      ),
    );
  }

  JoinedSelectStatement<HasResultSet, dynamic> _joined() {
    final t = _db.transactions;
    return _db.select(t).join([
      innerJoin(_db.categories, _db.categories.id.equalsExp(t.categoryId)),
      innerJoin(
        _db.paymentMethods,
        _db.paymentMethods.id.equalsExp(t.paymentMethodId),
      ),
    ])..orderBy([OrderingTerm.desc(t.occurredAt), OrderingTerm.desc(t.id)]);
  }

  TransactionDetails _toDetails(TypedResult row) => TransactionDetails(
    transaction: row.readTable(_db.transactions),
    category: row.readTable(_db.categories),
    paymentMethod: row.readTable(_db.paymentMethods),
  );

  TransactionsCompanion _companion(TransactionDraft d) => TransactionsCompanion(
    kind: Value(d.kind),
    amount: Value(d.amount),
    categoryId: Value(d.categoryId),
    paymentMethodId: Value(d.paymentMethodId),
    occurredAt: Value(d.occurredAt),
    note: Value(_blankToNull(d.note)),
    description: Value(_blankToNull(d.description)),
    receiptPath: Value(d.receiptPath),
  );

  static String? _blankToNull(String? s) =>
      s == null || s.trim().isEmpty ? null : s.trim();
}
