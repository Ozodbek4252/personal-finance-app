import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/core/time/clock.dart';
import 'package:personal_finance/data/db/app_database.dart';
import 'package:personal_finance/data/db/seed.dart';
import 'package:personal_finance/data/models/exchange_details.dart';
import 'package:personal_finance/data/models/transaction_details.dart';
import 'package:personal_finance/data/models/transaction_kind.dart';
import 'package:personal_finance/data/repositories/exchange_repository.dart';
import 'package:personal_finance/data/repositories/transaction_repository.dart';
import 'package:personal_finance/features/transactions/domain/list_entry.dart';
import 'package:personal_finance/features/transactions/domain/transaction_filter.dart';

import '../../helpers/test_db.dart';

TransactionDetails _tx(ListEntry e) => (e as TransactionEntry).item;

void main() {
  late AppDatabase db;
  late List<TransactionDetails> september;
  late List<ExchangeDetails> septemberExchanges;
  final sept = DateRange.month(DateTime(2026, 9));

  setUpAll(() async {
    db = memoryDb();
    await ensureDefaults(db);
    await seedSampleData(db);
    september = await TransactionRepository(
      db,
      const SystemClock(),
    ).watchBetween(sept.from, sept.to).first;
    septemberExchanges = await ExchangeRepository(
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
    expect(days.first.items.map((t) => _tx(t).transaction.note), [
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
    expect(
      byAmount.items.map((t) => _tx(t).transaction.amount),
      contains(35000),
    );

    expect(
      view(TransactionFilter(period: sept, query: 'hotel')).items,
      isEmpty,
    );
  });

  test('type and category filters', () {
    final income = view(
      TransactionFilter(period: sept, type: TypeFilter.income),
    );
    expect(
      income.items.every((t) => _tx(t).kind == TransactionKind.income),
      isTrue,
    );
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
    expect(_tx(largest.items.first).transaction.note, 'September salary');
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

  group('with exchanges', () {
    TransactionListView withEx(TransactionFilter f) =>
        TransactionListView.build(september, f, exchanges: septemberExchanges);

    test('sit between transactions but do not change the totals', () {
      final v = withEx(TransactionFilter(period: sept));
      expect(v.items.whereType<ExchangeEntry>(), hasLength(2));
      expect((v.income, v.expense, v.net), (15500000, 3050000, 12450000));

      final today = v.days.first;
      expect(today.net, 14545000, reason: 'the design day total');
      expect(today.items[1], isA<ExchangeEntry>(), reason: '11:30');
    });

    test('the Exchanges type shows only exchanges', () {
      final v = withEx(
        TransactionFilter(period: sept, type: TypeFilter.exchanges),
      );
      expect(v.items, hasLength(2));
      expect(v.items.every((e) => e is ExchangeEntry), isTrue);
      expect(TypeFilter.exchanges.kinds, isEmpty);
    });

    test('a category filter or Expenses hides exchanges', () {
      final groceriesId = september
          .firstWhere((t) => t.category.name == 'Groceries')
          .category
          .id;
      for (final f in [
        TransactionFilter(period: sept, categoryIds: {groceriesId}),
        TransactionFilter(period: sept, type: TypeFilter.expenses),
      ]) {
        expect(withEx(f).items.whereType<ExchangeEntry>(), isEmpty);
      }
    });

    test('search finds exchanges by word, method and amount', () {
      int count(String q) => withEx(
        TransactionFilter(period: sept, query: q),
      ).items.whereType<ExchangeEntry>().length;
      expect(count('exchange'), 2);
      expect(count('visa usd'), 1);
      expect(count('1 265 000'), 1);
      expect(count('100'), 1, reason: r'$100 in whole dollars');
      expect(count('taxi'), 0);
    });

    test('largest order uses the so’m that moved', () {
      final v = withEx(
        TransactionFilter(period: sept, sort: SortOrder.largest),
      );
      final amounts = v.items.map((e) => e.somAmount).toList();
      expect(amounts, orderedEquals([...amounts]..sort((a, b) => b - a)));
    });
  });
}
