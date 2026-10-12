import 'package:drift/drift.dart';

import '../models/currency.dart';
import '../models/transaction_kind.dart';
import 'app_database.dart';

/// Exchange fees in so'm are real spending, so each one is also saved
/// as an expense, linked to its exchange by `transactions.exchange_id`.
/// Fees in dollars stay on the exchange only, because expenses are in
/// so'm.

/// The category fees go to: "Commission" when the user has it, else
/// "Exchange fee", which is created when needed.
Future<int> feeCategoryId(AppDatabase db) async {
  final expenses = await (db.select(
    db.categories,
  )..where((c) => c.kind.equalsValue(TransactionKind.expense))).get();
  CategoryRow? named(String name) => expenses
      .where((c) => c.name.trim().toLowerCase() == name)
      .fold<CategoryRow?>(
        null,
        // Prefer one that is not archived.
        (best, c) =>
            best == null || (best.isArchived && !c.isArchived) ? c : best,
      );
  final found = named('commission') ?? named('exchange fee');
  if (found != null) return found.id;

  final last = expenses.fold<int>(
    -1,
    (m, c) => c.sortOrder > m ? c.sortOrder : m,
  );
  return db
      .into(db.categories)
      .insert(
        CategoriesCompanion.insert(
          name: 'Exchange fee',
          kind: TransactionKind.expense,
          iconKey: 'receipt',
          colorKey: 'gray',
          sortOrder: last + 1,
        ),
      );
}

/// Makes the fee expense of exchange [exchangeId] match the exchange:
/// removes the old one and adds a new one when there is a so'm fee.
/// Call it inside a database transaction.
Future<void> syncFeeExpense(AppDatabase db, int exchangeId) async {
  await (db.delete(
    db.transactions,
  )..where((t) => t.exchangeId.equals(exchangeId))).go();

  final exchange = await (db.select(
    db.exchanges,
  )..where((e) => e.id.equals(exchangeId))).getSingleOrNull();
  if (exchange == null || exchange.fee <= 0) return;
  final from = await (db.select(
    db.paymentMethods,
  )..where((m) => m.id.equals(exchange.fromMethodId))).getSingle();
  if (from.currency != Currency.uzs) return;

  await db
      .into(db.transactions)
      .insert(
        TransactionsCompanion.insert(
          kind: TransactionKind.expense,
          amount: exchange.fee,
          categoryId: await feeCategoryId(db),
          paymentMethodId: from.id,
          occurredAt: exchange.occurredAt,
          note: const Value('Exchange fee'),
          createdAt: exchange.createdAt,
          updatedAt: exchange.updatedAt,
          exchangeId: Value(exchange.id),
        ),
      );
}

/// Removes the fee expense of exchange [exchangeId], before the
/// exchange itself is deleted.
Future<void> deleteFeeExpense(AppDatabase db, int exchangeId) async {
  await (db.delete(
    db.transactions,
  )..where((t) => t.exchangeId.equals(exchangeId))).go();
}

/// Adds the fee expense for every exchange with a so'm fee that has
/// none yet. Used after updating to schema 3 and after a restore.
Future<void> addMissingFeeExpenses(AppDatabase db) async {
  final rows = await db
      .customSelect(
        'SELECT e.id AS id FROM exchanges e '
        'JOIN payment_methods pm ON pm.id = e.from_method_id '
        "WHERE e.fee > 0 AND pm.currency = 'uzs' AND NOT EXISTS "
        '(SELECT 1 FROM transactions t WHERE t.exchange_id = e.id)',
      )
      .get();
  for (final row in rows) {
    await syncFeeExpense(db, row.read<int>('id'));
  }
}
