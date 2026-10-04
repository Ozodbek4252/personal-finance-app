import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/core/time/clock.dart';
import 'package:personal_finance/data/bootstrap.dart';
import 'package:personal_finance/data/db/app_database.dart';
import 'package:personal_finance/data/models/transaction_kind.dart';
import 'package:personal_finance/data/providers/data_providers.dart';
import 'package:personal_finance/features/add_transaction/domain/amount_input.dart';
import 'package:personal_finance/features/add_transaction/providers/add_transaction_controller.dart';

import '../../helpers/test_db.dart';

class _FixedClock implements Clock {
  const _FixedClock(this.value);
  final DateTime value;
  @override
  DateTime now() => value;
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  final provider = addTransactionProvider(TransactionKind.expense);

  setUp(() async {
    db = memoryDb();
    final overrides = await bootstrap(db, sampleData: false);
    container = ProviderContainer(
      overrides: [
        ...overrides,
        clockProvider.overrideWithValue(
          _FixedClock(DateTime(2026, 9, 30, 15, 20)),
        ),
      ],
    );
    // Keep the auto-dispose provider and the lists alive during a test.
    container.listen(provider, (_, _) {});
    container.listen(paymentMethodsProvider, (_, _) {});
    await container.read(paymentMethodsProvider.future);
    // The default payment method comes from settings.
    container.listen(settingsProvider, (_, _) {});
    await container.read(settingsProvider.future);
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  /// Riverpod pauses providers nobody listens to, so listen while reading.
  Future<T> readAsync<T>(ProviderListenable<Future<T>> p) async {
    final sub = container.listen(p, (_, _) {});
    try {
      return await sub.read();
    } finally {
      sub.close();
    }
  }

  Future<int> categoryId(TransactionKind kind, String name) async =>
      (await readAsync(
        categoriesProvider(kind).future,
      )).firstWhere((c) => c.name == name).id;

  test('needs an amount and a category before saving', () async {
    final controller = container.read(provider.notifier);
    expect(container.read(provider).canSave, isFalse);

    controller.press(const DigitKey('5'));
    expect(container.read(provider).canSave, isFalse);
    expect(await controller.save(), isNull);

    controller.selectCategory(
      await categoryId(TransactionKind.expense, 'Food'),
    );
    expect(container.read(provider).canSave, isTrue);
  });

  test('saves with the default method, chosen day and current time', () async {
    final controller = container.read(provider.notifier);
    for (final k in ['3', '5', '000']) {
      controller.press(DigitKey(k));
    }
    controller
      ..selectCategory(
        await categoryId(TransactionKind.expense, 'Transportation'),
      )
      ..selectDay(DateTime(2026, 9, 28))
      ..setNote('  Taxi  ');

    final id = await controller.save();
    final saved = await container
        .read(transactionRepositoryProvider)
        .watchById(id!)
        .first;

    expect(saved!.transaction.amount, 35000);
    expect(saved.kind, TransactionKind.expense);
    expect(saved.category.name, 'Transportation');
    expect(saved.paymentMethod.name, 'Humo', reason: 'default method');
    expect(saved.transaction.note, 'Taxi');
    expect(saved.occurredAt, DateTime(2026, 9, 28, 15, 20));
  });

  test('each kind keeps its own category', () async {
    final controller = container.read(provider.notifier);
    final food = await categoryId(TransactionKind.expense, 'Food');
    final salary = await categoryId(TransactionKind.income, 'Salary');

    controller.selectCategory(food);
    controller.setKind(TransactionKind.income);
    expect(container.read(provider).categoryId, isNull);
    controller.selectCategory(salary);
    controller.setKind(TransactionKind.expense);
    expect(container.read(provider).categoryId, food);
  });

  test('a chosen payment method wins over the default', () async {
    final controller = container.read(provider.notifier);
    final methods = await readAsync(paymentMethodsProvider.future);
    final cash = methods.firstWhere((m) => m.name == 'Cash').id;
    controller.selectPaymentMethod(cash);
    expect(controller.effectivePaymentMethodId(), cash);
  });
}
