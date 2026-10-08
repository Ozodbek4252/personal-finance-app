import '../../../core/time/clock.dart';
import '../../../data/models/exchange_details.dart';
import '../../../data/models/transaction_details.dart';
import '../../../data/models/transaction_kind.dart';
import 'list_entry.dart';

/// "All", "Expenses", "Income" or "Exchanges".
enum TypeFilter {
  all('All'),
  expenses('Expenses'),
  income('Income'),
  exchanges('Exchanges');

  const TypeFilter(this.label);
  final String label;

  bool accepts(TransactionKind kind) => switch (this) {
    all => true,
    expenses => kind == TransactionKind.expense,
    income => kind == TransactionKind.income,
    exchanges => false,
  };

  bool get acceptsExchanges => this == all || this == exchanges;

  /// Categories that can be picked with this type.
  List<TransactionKind> get kinds => switch (this) {
    all => TransactionKind.values,
    expenses => const [TransactionKind.expense],
    income => const [TransactionKind.income],
    exchanges => const [],
  };
}

enum SortOrder {
  newest('Newest first', 'Newest'),
  oldest('Oldest first', 'Oldest'),
  largest('Largest amount', 'Largest');

  const SortOrder(this.label, this.shortLabel);
  final String label;

  /// For the small sort chip in results mode.
  final String shortLabel;

  /// Date orders show day groups; amount order shows one flat list.
  bool get groupsByDay => this != largest;
}

/// A date range: [from] included, [to] not included.
class DateRange {
  const DateRange(this.from, this.to);

  /// The calendar month that contains [day].
  factory DateRange.month(DateTime day) =>
      DateRange(monthStart(day), nextMonthStart(day));

  final DateTime from;
  final DateTime to;

  /// True when the range is exactly one calendar month.
  bool get isWholeMonth =>
      from == monthStart(from) && to == nextMonthStart(from);

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

/// Everything that narrows down the transaction list.
class TransactionFilter {
  const TransactionFilter({
    required this.period,
    this.query = '',
    this.type = TypeFilter.all,
    this.categoryIds = const {},
    this.sort = SortOrder.newest,
  });

  /// Null means all time.
  final DateRange? period;
  final String query;
  final TypeFilter type;

  /// Empty means every category.
  final Set<int> categoryIds;
  final SortOrder sort;

  TransactionFilter copyWith({
    DateRange? Function()? period,
    String? query,
    TypeFilter? type,
    Set<int>? categoryIds,
    SortOrder? sort,
  }) => TransactionFilter(
    period: period == null ? this.period : period(),
    query: query ?? this.query,
    type: type ?? this.type,
    categoryIds: categoryIds ?? this.categoryIds,
    sort: sort ?? this.sort,
  );

  /// True when search text, a type or a category narrows the list.
  /// Then the screen shows "N results" instead of the normal totals.
  bool get hasFilters =>
      query.trim().isNotEmpty ||
      type != TypeFilter.all ||
      categoryIds.isNotEmpty;

  /// True if [t] passes the type, category and search filters.
  /// The period is applied by the database query.
  bool matches(TransactionDetails t) {
    if (!type.accepts(t.kind)) return false;
    if (categoryIds.isNotEmpty && !categoryIds.contains(t.category.id)) {
      return false;
    }
    return matchesQuery(t, query);
  }

  /// True if exchange [e] passes the filters. Exchanges have no
  /// category, so a category filter hides them.
  bool matchesExchange(ExchangeDetails e) {
    if (!type.acceptsExchanges || categoryIds.isNotEmpty) return false;
    return matchesExchangeQuery(e, query);
  }

  /// Search looks at the note, the two methods, the word "exchange",
  /// the currency codes and both amounts ("1265000" or "100").
  static bool matchesExchangeQuery(ExchangeDetails e, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final row = e.exchange;
    final text = [
      'exchange',
      row.note,
      e.from.name,
      e.to.name,
      '${e.fromCurrency.code} ${e.toCurrency.code}',
    ].whereType<String>().join(' ').toLowerCase();
    if (text.contains(q)) return true;
    final digits = q.replaceAll(RegExp(r'[\s $]'), '');
    if (!RegExp(r'^\d+$').hasMatch(digits)) return false;
    // Dollar amounts are searched in whole dollars.
    String whole(int minor, int units) => '${minor ~/ units}';
    return [
      whole(row.fromAmount, e.fromCurrency.minorUnits),
      whole(row.toAmount, e.toCurrency.minorUnits),
    ].any((a) => a.contains(digits));
  }

  /// Search looks at the note, description, category, payment method
  /// and amount. "taxi" finds "Taxi · Yandex Go"; "35000" or "35 000"
  /// finds 35 000.
  static bool matchesQuery(TransactionDetails t, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final row = t.transaction;
    final text = [
      row.note,
      row.description,
      t.category.name,
      t.paymentMethod.name,
    ].whereType<String>().join(' ').toLowerCase();
    if (text.contains(q)) return true;
    final digits = q.replaceAll(RegExp(r'[\s ]'), '');
    return RegExp(r'^\d+$').hasMatch(digits) &&
        row.amount.toString().contains(digits);
  }
}

/// One day in the grouped list.
class DayGroup {
  const DayGroup({required this.day, required this.items});

  /// Midnight of the day.
  final DateTime day;
  final List<ListEntry> items;

  /// Income − expenses on this day. Exchanges do not count.
  int get net => items.fold(0, (sum, e) => sum + e.signedSom);
}

/// The filtered list, ready to show.
class TransactionListView {
  const TransactionListView({
    required this.items,
    required this.income,
    required this.expense,
    required this.sort,
  });

  /// Builds the view from the transactions and exchanges of the
  /// filter's period.
  factory TransactionListView.build(
    List<TransactionDetails> periodItems,
    TransactionFilter filter, {
    List<ExchangeDetails> exchanges = const [],
  }) {
    final transactions = periodItems.where(filter.matches).toList();
    final items = <ListEntry>[
      for (final t in transactions) TransactionEntry(t),
      for (final e in exchanges)
        if (filter.matchesExchange(e)) ExchangeEntry(e),
    ];
    int newestFirst(ListEntry a, ListEntry b) {
      final byDate = b.occurredAt.compareTo(a.occurredAt);
      return byDate != 0 ? byDate : b.id.compareTo(a.id);
    }

    switch (filter.sort) {
      case SortOrder.newest:
        items.sort(newestFirst);
      case SortOrder.oldest:
        items.sort((a, b) => newestFirst(b, a));
      case SortOrder.largest:
        items.sort((a, b) => b.somAmount.compareTo(a.somAmount));
    }
    var income = 0;
    var expense = 0;
    for (final t in transactions) {
      if (t.kind == TransactionKind.income) {
        income += t.transaction.amount;
      } else {
        expense += t.transaction.amount;
      }
    }
    return TransactionListView(
      items: items,
      income: income,
      expense: expense,
      sort: filter.sort,
    );
  }

  final List<ListEntry> items;
  final int income;
  final int expense;
  final SortOrder sort;

  int get net => income - expense;

  /// Items grouped by day, in the current sort order.
  List<DayGroup> get days {
    final groups = <DayGroup>[];
    for (final t in items) {
      final d = t.occurredAt;
      final day = DateTime(d.year, d.month, d.day);
      if (groups.isNotEmpty && groups.last.day == day) {
        groups.last.items.add(t);
      } else {
        groups.add(DayGroup(day: day, items: [t]));
      }
    }
    return groups;
  }
}
