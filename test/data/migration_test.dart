import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/data/db/app_database.dart';
import 'package:personal_finance/data/db/seed.dart';
import 'package:personal_finance/core/time/clock.dart';
import 'package:personal_finance/data/models/currency.dart';
import 'package:personal_finance/data/models/transaction_kind.dart';
import 'package:personal_finance/data/repositories/transaction_repository.dart';

import '../generated_migrations/schema.dart';
import '../generated_migrations/schema_v1.dart' as v1;
import '../generated_migrations/schema_v2.dart' as v2;

/// Real user data lives in old databases. These tests open a database
/// made by an older app version and check that an update keeps it.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  for (final start in [1, 2]) {
    test('$start → 3 gives the same tables as a fresh install', () async {
      final schema = await verifier.schemaAt(start);
      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 3);
      await db.close();
    });
  }

  test('1 → 2 keeps all data and adds "Cash (USD)"', () async {
    final schema = await verifier.schemaAt(1);

    // Fill the database the way version 1 of the app did.
    final old = v1.DatabaseAtV1(schema.newConnection());
    final at = DateTime(2026, 10, 6, 12);
    // Drift stores dates as Unix seconds.
    final atSeconds = at.millisecondsSinceEpoch ~/ 1000;
    await old.batch((b) {
      b.insert(
        old.categories,
        v1.CategoriesCompanion.insert(
          name: 'Groceries',
          kind: 'expense',
          iconKey: 'cart',
          colorKey: 'green',
          sortOrder: 0,
        ),
      );
      for (final (i, name) in ['Cash', 'Humo'].indexed) {
        b.insert(
          old.paymentMethods,
          v1.PaymentMethodsCompanion.insert(
            name: name,
            iconKey: 'card',
            sortOrder: i,
            openingBalance: Value(i == 1 ? 1000000 : 0),
          ),
        );
      }
      b.insert(
        old.transactions,
        v1.TransactionsCompanion.insert(
          kind: 'expense',
          amount: 35000,
          categoryId: 1,
          paymentMethodId: 2,
          occurredAt: atSeconds,
          note: const Value('Korzinka'),
          createdAt: atSeconds,
          updatedAt: atSeconds,
        ),
      );
      b.insert(
        old.settings,
        v1.SettingsCompanion.insert(key: 'userName', value: 'Ozodbek'),
      );
    });
    await old.close();

    final db = AppDatabase(schema.newConnection());
    final methods = await (db.select(
      db.paymentMethods,
    )..orderBy([(m) => OrderingTerm.asc(m.sortOrder)])).get();
    expect(
      [for (final m in methods) (m.name, m.currency, m.sortOrder)],
      [
        ('Cash', Currency.uzs, 0),
        ('Humo', Currency.uzs, 1),
        ('Cash (USD)', Currency.usd, 2),
      ],
    );
    expect(methods[1].openingBalance, 1000000);

    final tx = await db.select(db.transactions).getSingle();
    expect(tx.amount, 35000);
    expect(tx.note, 'Korzinka');
    expect(tx.occurredAt, at);
    expect((await db.select(db.settings).getSingle()).value, 'Ozodbek');
    expect(await db.select(db.exchanges).get(), isEmpty);

    // Starting the app again does not add the defaults a second time.
    await ensureDefaults(db);
    expect(await db.paymentMethods.count().getSingle(), 3);
    await db.close();
  });

  test('1 → 2 on an empty database adds nothing extra', () async {
    final schema = await verifier.schemaAt(1);
    final db = AppDatabase(schema.newConnection());
    expect(await db.paymentMethods.count().getSingle(), 0);

    // First start then adds the normal defaults, with one dollar method.
    await ensureDefaults(db);
    final usd = await (db.select(
      db.paymentMethods,
    )..where((m) => m.currency.equalsValue(Currency.usd))).get();
    expect([for (final m in usd) m.name], ['Cash (USD)']);
    await db.close();
  });

  group('2 → 3', () {
    final at = DateTime(2026, 10, 11, 18, 12);
    final atSeconds = at.millisecondsSinceEpoch ~/ 1000;

    /// A version 2 database like the phone's: Humo, Cash (USD), a $300
    /// exchange with a 24 900 so'm fee, and a $10 sale with a $1 fee.
    Future<InitializedSchema> fill(
      SchemaVerifier verifier, {
      required bool commission,
    }) async {
      final schema = await verifier.schemaAt(2);
      final old = v2.DatabaseAtV2(schema.newConnection());
      await old.batch((b) {
        b.insert(
          old.categories,
          v2.CategoriesCompanion.insert(
            name: 'Groceries',
            kind: 'expense',
            iconKey: 'cart',
            colorKey: 'green',
            sortOrder: 0,
          ),
        );
        if (commission) {
          b.insert(
            old.categories,
            v2.CategoriesCompanion.insert(
              name: 'Commission',
              kind: 'expense',
              iconKey: 'receipt',
              colorKey: 'red',
              sortOrder: 1,
            ),
          );
        }
        b.insert(
          old.paymentMethods,
          v2.PaymentMethodsCompanion.insert(
            name: 'Humo',
            iconKey: 'card',
            sortOrder: 0,
            openingBalance: const Value(10000000),
          ),
        );
        b.insert(
          old.paymentMethods,
          v2.PaymentMethodsCompanion.insert(
            name: 'Cash (USD)',
            iconKey: 'cash',
            sortOrder: 1,
            currency: const Value('usd'),
          ),
        );
        b.insert(
          old.exchanges,
          v2.ExchangesCompanion.insert(
            fromMethodId: 1,
            fromAmount: 3569370,
            toMethodId: 2,
            toAmount: 30000,
            rate: 11897.9,
            fee: const Value(24900),
            occurredAt: atSeconds,
            createdAt: atSeconds,
            updatedAt: atSeconds,
          ),
        );
        b.insert(
          old.exchanges,
          v2.ExchangesCompanion.insert(
            fromMethodId: 2,
            fromAmount: 1000,
            toMethodId: 1,
            toAmount: 118979,
            rate: 11897.9,
            fee: const Value(100),
            occurredAt: atSeconds + 60,
            createdAt: atSeconds + 60,
            updatedAt: atSeconds + 60,
          ),
        );
      });
      await old.close();
      return schema;
    }

    test('a so’m fee becomes a Commission expense; balances stay', () async {
      final schema = await fill(verifier, commission: true);
      final db = AppDatabase(schema.newConnection());

      final fee = await db.select(db.transactions).getSingle();
      final commission = await (db.select(
        db.categories,
      )..where((c) => c.name.equals('Commission'))).getSingle();
      expect(
        (fee.kind, fee.amount, fee.categoryId, fee.paymentMethodId),
        (TransactionKind.expense, 24900, commission.id, 1),
      );
      expect(
        (fee.exchangeId, fee.occurredAt, fee.note),
        (1, at, 'Exchange fee'),
      );

      // Same balances as before: the fee is taken once.
      final repo = TransactionRepository(db, const SystemClock());
      expect(
        (await repo.getBalances())[1],
        10000000 - 3569370 - 24900 + 118979,
      );
      expect(
        (await repo.getBalances(currency: Currency.usd))[2],
        30000 - 1000 - 100,
      );
      await db.close();
    });

    test('without Commission it makes an "Exchange fee" category', () async {
      final schema = await fill(verifier, commission: false);
      final db = AppDatabase(schema.newConnection());
      final fee = await db.select(db.transactions).getSingle();
      final category = await (db.select(
        db.categories,
      )..where((c) => c.id.equals(fee.categoryId))).getSingle();
      expect(category.name, 'Exchange fee');
      expect(category.kind, TransactionKind.expense);
      await db.close();
    });
  });
}
