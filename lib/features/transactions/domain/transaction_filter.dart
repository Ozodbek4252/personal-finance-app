import '../../../core/time/clock.dart';
import '../../../data/models/transaction_details.dart';
import '../../../data/models/transaction_kind.dart';

/// "All", "Expenses" or "Income".
enum TypeFilter {
  all('All'),
  expenses('Expenses'),
  income('Income');

  const TypeFilter(this.label);
  final String label;

  bool accepts(TransactionKind kind) => switch (this) {
    all => true,
    expenses => kind == TransactionKind.expense,
    income => kind == TransactionKind.income,
  };
}

enum SortOrder {
  newest('Newest first'),
  oldest('Oldest first'),
  largest('Largest amount');

  const SortOrder(this.label);
  final String label;

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

  /// True if [t] passes the type, category and search filters.
  /// The period is applied by the database query.
  bool matches(TransactionDetails t) {
    if (!type.accepts(t.kind)) return false;
    if (categoryIds.isNotEmpty && !categoryIds.contains(t.category.id)) {
      return false;
    }
    return matchesQuery(t, query);
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
  final List<TransactionDetails> items;

  /// Income − expenses on this day.
  int get net => items.fold(0, (sum, t) => sum + t.signedAmount);
}

/// The filtered list, ready to show.
class TransactionListView {
  const TransactionListView({
    required this.items,
    required this.income,
    required this.expense,
    required this.sort,
  });

  /// Builds the view from the transactions of the filter's period.
  factory TransactionListView.build(
    List<TransactionDetails> periodItems,
    TransactionFilter filter,
  ) {
    final items = periodItems.where(filter.matches).toList();
    switch (filter.sort) {
      case SortOrder.newest:
        break; // The database already returns newest first.
      case SortOrder.oldest:
        items.sort((a, b) {
          final byDate = a.occurredAt.compareTo(b.occurredAt);
          return byDate != 0 ? byDate : a.id.compareTo(b.id);
        });
      case SortOrder.largest:
        items.sort(
          (a, b) => b.transaction.amount.compareTo(a.transaction.amount),
        );
    }
    var income = 0;
    var expense = 0;
    for (final t in items) {
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

  final List<TransactionDetails> items;
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
