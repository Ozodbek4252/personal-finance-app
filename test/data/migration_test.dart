import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/data/db/app_database.dart';
import 'package:personal_finance/data/db/seed.dart';
import 'package:personal_finance/data/models/currency.dart';

import '../generated_migrations/schema.dart';
import '../generated_migrations/schema_v1.dart' as v1;

/// Real user data lives in old databases. These tests open a database
/// made by an older app version and check that an update keeps it.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('1 → 2 gives the same tables as a fresh install', () async {
    final schema = await verifier.schemaAt(1);
    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 2);
    await db.close();
  });

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
}
