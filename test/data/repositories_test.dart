import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/core/time/clock.dart';
import 'package:personal_finance/data/db/app_database.dart';
import 'package:personal_finance/data/db/seed.dart';
import 'package:personal_finance/data/models/transaction_details.dart';
import 'package:personal_finance/data/models/transaction_kind.dart';
import 'package:personal_finance/data/repositories/category_repository.dart';
import 'package:personal_finance/data/repositories/payment_method_repository.dart';
import 'package:personal_finance/data/repositories/settings_repository.dart';
import 'package:personal_finance/data/repositories/transaction_repository.dart';

import '../helpers/test_db.dart';

class _FixedClock implements Clock {
  _FixedClock(this.value);
  DateTime value;
  @override
  DateTime now() => value;
}

void main() {
  late AppDatabase db;
  late _FixedClock clock;
  late TransactionRepository transactions;
  late CategoryRepository categories;
  late PaymentMethodRepository methods;
  late int groceries;
  late int salary;
  late int humo;

  setUp(() async {
    db = memoryDb();
    clock = _FixedClock(DateTime(2026, 9, 30, 15));
    transactions = TransactionRepository(db, clock);
    categories = CategoryRepository(db);
    methods = PaymentMethodRepository(db);
    await ensureDefaults(db);
    final cats = await categories.watchAll(includeArchived: true).first;
    groceries = cats.firstWhere((c) => c.name == 'Groceries').id;
    salary = cats.firstWhere((c) => c.name == 'Salary').id;
    humo = (await methods.watchAll().first)
        .firstWhere((m) => m.name == 'Humo')
        .id;
  });
  tearDown(() => db.close());

  TransactionDraft expense(int amount, DateTime at, {String? note}) =>
      TransactionDraft(
        kind: TransactionKind.expense,
        amount: amount,
        categoryId: groceries,
        paymentMethodId: humo,
        occurredAt: at,
        note: note,
      );

  group('TransactionRepository', () {
    test('add, update and delete', () async {
      final id = await transactions.add(
        expense(420000, DateTime(2026, 9, 30, 13, 40), note: '  Korzinka '),
      );
      var row = (await transactions.watchById(id).first)!;
      expect(row.signedAmount, -420000);
      expect(row.transaction.note, 'Korzinka', reason: 'text is trimmed');
      expect(row.category.name, 'Groceries');
      expect(row.paymentMethod.name, 'Humo');
      expect(row.transaction.createdAt, clock.value);

      clock.value = DateTime(2026, 9, 30, 16);
      await transactions.update(id, expense(400000, row.occurredAt, note: ' '));
      row = (await transactions.watchById(id).first)!;
      expect(row.transaction.amount, 400000);
      expect(row.transaction.note, isNull, reason: 'blank text is removed');
      expect(row.transaction.updatedAt, clock.value);

      await transactions.delete(id);
      expect(await transactions.watchById(id).first, isNull);
    });

    test('duplicate copies values with the current time', () async {
      final id = await transactions.add(
        expense(96000, DateTime(2026, 9, 25, 19, 2), note: 'Makro'),
      );
      final copyId = await transactions.duplicate(id);
      final copy = (await transactions.watchById(copyId).first)!;
      expect(copy.transaction.amount, 96000);
      expect(copy.transaction.note, 'Makro');
      expect(copy.occurredAt, clock.value);
    });

    test('watchBetween includes the start and excludes the end', () async {
      await transactions.add(expense(1000, DateTime(2026, 9)));
      await transactions.add(expense(2000, DateTime(2026, 9, 30, 23, 59)));
      await transactions.add(expense(3000, DateTime(2026, 10)));
      final sept = await transactions
          .watchBetween(DateTime(2026, 9), DateTime(2026, 10))
          .first;
      expect(sept.map((t) => t.transaction.amount), [2000, 1000]);
    });

    test('balances add opening balance, income and expenses', () async {
      await methods.setOpeningBalance(humo, 1000000);
      await transactions.add(expense(300000, DateTime(2026, 9, 1)));
      await transactions.add(
        TransactionDraft(
          kind: TransactionKind.income,
          amount: 500000,
          categoryId: salary,
          paymentMethodId: humo,
          occurredAt: DateTime(2026, 9, 2),
        ),
      );
      final balances = await transactions.watchBalances().first;
      expect(balances[humo], 1200000);
      expect(balances.values.where((b) => b != 0), hasLength(1));
    });

    test('streams emit again after a change', () async {
      final stream = transactions.watchRecent(limit: 10);
      final expectation = expectLater(
        stream.map((list) => list.length),
        emitsInOrder([0, 1]),
      );
      await transactions.add(expense(1000, DateTime(2026, 9, 1)));
      await expectation;
    });

    test('amount must be positive', () async {
      expect(
        () => db
            .into(db.transactions)
            .insert(
              TransactionsCompanion.insert(
                kind: TransactionKind.expense,
                amount: 0,
                categoryId: groceries,
                paymentMethodId: humo,
                occurredAt: DateTime(2026),
                createdAt: DateTime(2026),
                updatedAt: DateTime(2026),
              ),
            ),
        throwsA(anything),
      );
    });
  });

  group('CategoryRepository', () {
    test('add puts the new category last in its kind', () async {
      final id = await categories.add(
        name: ' Coffee ',
        kind: TransactionKind.expense,
        iconKey: 'coffee',
        colorKey: 'brown',
      );
      final list = await categories
          .watchAll(kind: TransactionKind.expense)
          .first;
      expect(list.last.id, id);
      expect(list.last.name, 'Coffee');
      expect(list.last.sortOrder, 11);
    });

    test('reorder and archive', () async {
      final list = await categories
          .watchAll(kind: TransactionKind.income)
          .first;
      final reversed = list.reversed.map((c) => c.id).toList();
      await categories.reorder(reversed);
      var after = await categories.watchAll(kind: TransactionKind.income).first;
      expect(after.map((c) => c.id), reversed);

      await categories.archive(reversed.first);
      after = await categories.watchAll(kind: TransactionKind.income).first;
      expect(after, hasLength(5));
    });
  });

  test('PaymentMethodRepository adds custom methods last', () async {
    final id = await methods.addCustom('Payme');
    final list = await methods.watchAll().first;
    expect(list.last.id, id);
    expect(list.last.isCustom, isTrue);
  });

  test('SettingsRepository saves and reads values', () async {
    final settings = SettingsRepository(db);
    await settings.setThemeMode(ThemeMode.dark);
    await settings.setBalanceHidden(true);
    final loaded = await settings.load();
    expect(loaded.themeMode, ThemeMode.dark);
    expect(loaded.balanceHidden, isTrue);
    expect(AppSettings.empty.themeMode, ThemeMode.system);
  });
}
