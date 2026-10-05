import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/core/time/clock.dart';
import 'package:personal_finance/data/db/app_database.dart';
import 'package:personal_finance/data/db/seed.dart';
import 'package:personal_finance/data/models/transaction_details.dart';
import 'package:personal_finance/data/models/transaction_kind.dart';
import 'package:personal_finance/data/repositories/transaction_repository.dart';
import 'package:personal_finance/features/transactions/domain/transaction_filter.dart';

import '../../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late List<TransactionDetails> september;
  final sept = DateRange.month(DateTime(2026, 9));

  setUpAll(() async {
    db = memoryDb();
    await ensureDefaults(db);
    await seedSampleData(db);
    september = await TransactionRepository(
      db,
      const SystemClock(),
    ).watchBetween(sept.from, sept.to).first;
  });
  tearDownAll(() => db.close());

  TransactionListView view(TransactionFilter f) =>
      TransactionListView.build(september, f);

  test('totals and day groups match the Transaction history board', () {
    final v = view(TransactionFilter(period: sept));
    expect(v.income, 15500000);
    expect(v.expense, 3050000);
    expect(v.net, 12450000);

    final days = v.days;
    expect(days.first.day, DateTime(2026, 9, 30));
    expect(days.first.net, 14545000);
    expect(days[1].net, -205000);
    expect(days.first.items.map((t) => t.transaction.note), [
      'Korzinka',
      'September salary',
      'Taxi · Yandex Go',
    ]);
  });

  test('search finds notes, categories and amounts', () {
    final taxi = view(TransactionFilter(period: sept, query: 'TAXI'));
    expect(taxi.items, hasLength(4));
    expect(taxi.expense, 148000);

    final byCategory = view(TransactionFilter(period: sept, query: 'health'));
    expect(byCategory.items, hasLength(2));

    final byAmount = view(TransactionFilter(period: sept, query: '35 000'));
    expect(byAmount.items.map((t) => t.transaction.amount), contains(35000));

    expect(
      view(TransactionFilter(period: sept, query: 'hotel')).items,
      isEmpty,
    );
  });

  test('type and category filters', () {
    final income = view(
      TransactionFilter(period: sept, type: TypeFilter.income),
    );
    expect(income.items.every((t) => t.kind == TransactionKind.income), isTrue);
    expect(income.items, hasLength(2));

    final groceriesId = september
        .firstWhere((t) => t.category.name == 'Groceries')
        .category
        .id;
    final groceries = view(
      TransactionFilter(period: sept, categoryIds: {groceriesId}),
    );
    expect(groceries.items, hasLength(6));
    expect(groceries.expense, 820000);
  });

  test('sort orders', () {
    final largest = view(
      TransactionFilter(period: sept, sort: SortOrder.largest),
    );
    expect(largest.items.first.transaction.note, 'September salary');
    expect(largest.sort.groupsByDay, isFalse);

    final oldest = view(
      TransactionFilter(period: sept, sort: SortOrder.oldest),
    );
    final dates = oldest.items.map((t) => t.occurredAt).toList();
    expect(dates, orderedEquals([...dates]..sort()));
    expect(oldest.days.first.day.isBefore(oldest.days.last.day), isTrue);
  });

  test('DateRange.month knows whole months', () {
    expect(sept.isWholeMonth, isTrue);
    expect(
      DateRange(DateTime(2026, 9, 1), DateTime(2026, 9, 15)).isWholeMonth,
      isFalse,
    );
  });
}
