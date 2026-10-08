import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/async/combine.dart';
import '../../../data/models/exchange_details.dart';
import '../../../data/models/transaction_details.dart';
import '../../../data/providers/data_providers.dart';
import '../domain/transaction_filter.dart';

/// The current filters on the Transactions tab. Kept while switching tabs.
final transactionFilterProvider =
    NotifierProvider<TransactionFilterNotifier, TransactionFilter>(
      TransactionFilterNotifier.new,
    );

class TransactionFilterNotifier extends Notifier<TransactionFilter> {
  @override
  TransactionFilter build() =>
      TransactionFilter(period: DateRange.month(ref.read(clockProvider).now()));

  void setQuery(String query) => state = state.copyWith(query: query);
  void setType(TypeFilter type) => state = state.copyWith(type: type);
  void setSort(SortOrder sort) => state = state.copyWith(sort: sort);
  void setPeriod(DateRange? period) =>
      state = state.copyWith(period: () => period);
  void setCategories(Set<int> ids) => state = state.copyWith(categoryIds: ids);

  /// Replaces all filters at once, from the filter sheet.
  void apply(TransactionFilter filter) => state = filter;

  /// Back to the defaults: this month, everything, newest first.
  void reset() => state = build();

  /// Clears type, categories and the date range, but keeps the search.
  void clearFilters() => state = build().copyWith(query: state.query);
}

/// Far enough back and ahead to mean "all time".
final allTimeRange = DateRange(DateTime(1970), DateTime(3000));

/// Transactions in a date range, newest first.
final periodTransactionsProvider =
    StreamProvider.family<List<TransactionDetails>, DateRange>(
      (ref, range) => ref
          .watch(transactionRepositoryProvider)
          .watchBetween(range.from, range.to),
    );

/// Exchanges in a date range, newest first.
final periodExchangesProvider =
    StreamProvider.family<List<ExchangeDetails>, DateRange>(
      (ref, range) => ref
          .watch(exchangeRepositoryProvider)
          .watchBetween(range.from, range.to),
    );

/// The filtered, sorted list for [filter], with its totals.
final filteredListProvider = Provider.autoDispose
    .family<AsyncValue<TransactionListView>, TransactionFilter>((ref, filter) {
      final range = filter.period ?? allTimeRange;
      return combine2(
        ref.watch(periodTransactionsProvider(range)),
        ref.watch(periodExchangesProvider(range)),
      ).whenData(
        (v) => TransactionListView.build(v.$1, filter, exchanges: v.$2),
      );
    });

/// The list for the filters on the Transactions tab.
final transactionListProvider = Provider<AsyncValue<TransactionListView>>(
  (ref) =>
      ref.watch(filteredListProvider(ref.watch(transactionFilterProvider))),
);
