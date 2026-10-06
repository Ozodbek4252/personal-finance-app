import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/data/models/currency.dart';
import 'package:personal_finance/core/time/clock.dart';
import 'package:personal_finance/data/db/app_database.dart';
import 'package:personal_finance/data/db/seed.dart';
import 'package:personal_finance/data/models/transaction_details.dart';
import 'package:personal_finance/data/models/transaction_kind.dart';
import 'package:personal_finance/data/repositories/settings_repository.dart';
import 'package:personal_finance/data/repositories/transaction_repository.dart';

import '../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late TransactionRepository repo;

  setUp(() async {
    db = memoryDb();
    repo = TransactionRepository(db, const SystemClock());
    await ensureDefaults(db);
  });
  tearDown(() => db.close());

  group('defaults', () {
    test('adds the design categories and payment methods', () async {
      final cats = await db.select(db.categories).get();
      final expense = cats.where((c) => c.kind == TransactionKind.expense);
      final income = cats.where((c) => c.kind == TransactionKind.income);
      expect(expense.map((c) => c.name).take(9), [
        'Transportation', 'Groceries', 'Food', 'Shopping', 'Bills', //
        'Health', 'Education', 'Emergency', 'Other',
      ]);
      expect(expense, hasLength(11));
      expect(income.map((c) => c.name), [
        'Salary',
        'Advance',
        'Bonus',
        'Freelance',
        'Gift',
        'Other',
      ]);

      final methods = await db.select(db.paymentMethods).get();
      expect(methods, hasLength(9));
      expect(methods.where((m) => m.isCustom).single.name, 'Click wallet');
      expect(
        methods.where((m) => m.currency == Currency.usd).single.name,
        'Cash (USD)',
      );

      final settings = await SettingsRepository(db).load();
      final humo = methods.firstWhere((m) => m.name == 'Humo');
      expect(settings.defaultPaymentMethodId, humo.id);
    });

    test('runs only once', () async {
      await ensureDefaults(db);
      expect(await db.categories.count().getSingle(), 17);
    });
  });

  group('sample data', () {
    setUp(() => seedSampleData(db));

    test('month totals match the Monthly overview board', () async {
      final totals = await repo.watchMonthTotals().first;
      expect(
        [for (final t in totals) (t.month.month, t.income, t.expense)],
        [
          (4, 14000000, 3480000),
          (5, 14000000, 3720000),
          (6, 15200000, 4650000),
          (7, 14500000, 3900000),
          (8, 15000000, 4280000),
          (9, 15500000, 3050000),
        ],
      );
      expect(totals.last.savings, 12450000);
      expect(totals.last.savingsRate!.toStringAsFixed(1), '80.3');
      expect(totals[4].savingsRate!.toStringAsFixed(1), '71.5');
    });

    test(
      'September categories match the Dashboard and Categories boards',
      () async {
        final sept = await _september(repo);
        final byCategory = <String, (int, int)>{};
        for (final t in sept.where((t) => t.kind == TransactionKind.expense)) {
          final (sum, count) = byCategory[t.category.name] ?? (0, 0);
          byCategory[t.category.name] = (sum + t.transaction.amount, count + 1);
        }
        expect(byCategory, {
          'Groceries': (820000, 6),
          'Emergency': (500000, 1),
          'Shopping': (470000, 3),
          'Transportation': (410000, 14),
          'Food': (380000, 9),
          'Bills': (290000, 4),
          'Health': (180000, 2),
        });
      },
    );

    test('day totals match the Transaction history board', () async {
      final sept = await _september(repo);
      int dayTotal(int day) => sept
          .where((t) => t.occurredAt.day == day)
          .fold(0, (sum, t) => sum + t.signedAmount);
      expect(dayTotal(30), 14545000);
      expect(dayTotal(29), -205000);
      expect(dayTotal(27), -850000);
      expect(dayTotal(25), 404000);
    });

    test('recent list and "taxi" search match the boards', () async {
      final recent = await repo.watchRecent().first;
      expect(recent.map((t) => t.transaction.note), [
        'Korzinka',
        'September salary',
        'Taxi · Yandex Go',
        'Home internet',
      ]);

      final taxi = (await _september(repo)).where(
        (t) => (t.transaction.note ?? '').toLowerCase().contains('taxi'),
      );
      expect(taxi, hasLength(4));
      expect(taxi.fold(0, (s, t) => s + t.transaction.amount), 148000);
    });

    test('transportation trend matches the Statistics board', () async {
      final all = await repo
          .watchBetween(DateTime(2026, 4), DateTime(2026, 10))
          .first;
      final byMonth = <int, int>{};
      for (final t in all.where((t) => t.category.name == 'Transportation')) {
        byMonth.update(
          t.occurredAt.month,
          (v) => v + t.transaction.amount,
          ifAbsent: () => t.transaction.amount,
        );
      }
      expect(byMonth, {
        4: 290000,
        5: 320000,
        6: 365000,
        7: 300000,
        8: 347000,
        9: 410000,
      });
    });

    test('no payment method has a negative balance', () async {
      final balances = await repo.watchBalances().first;
      expect(balances.values.every((b) => b >= 0), isTrue);
    });

    test('has \$500 in two dollar methods, bought for 6 271 000', () async {
      final usd = await repo.watchBalances(currency: Currency.usd).first;
      expect(usd.values.fold(0, (a, b) => a + b), 50000);
      expect(usd.values.toSet(), {30000, 20000});
      final exchanges = await db.select(db.exchanges).get();
      expect(
        exchanges.map((e) => e.fromAmount).fold(0, (a, b) => a + b),
        6271000,
      );
      expect(await db.select(db.exchangeRates).get(), hasLength(6));
    });

    test('is added only once', () async {
      final before = await db.transactions.count().getSingle();
      await seedSampleData(db);
      expect(await db.transactions.count().getSingle(), before);
    });
  });

  test('splitAmount keeps the exact total', () {
    for (final (total, count) in [(262000, 10), (304000, 4), (1000, 1)]) {
      final parts = splitAmount(total, count);
      expect(parts, hasLength(count));
      expect(parts.reduce((a, b) => a + b), total);
      expect(parts.every((p) => p > 0), isTrue);
    }
  });
}

Future<List<TransactionDetails>> _september(TransactionRepository repo) =>
    repo.watchBetween(DateTime(2026, 9), DateTime(2026, 10)).first;
