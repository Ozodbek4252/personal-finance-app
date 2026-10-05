import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers/data_providers.dart';
import '../../transactions/domain/transaction_filter.dart';
import '../../transactions/providers/transactions_providers.dart';
import '../domain/stat_period.dart';
import '../domain/statistics_data.dart';

/// The period shown on the Statistics tab. Starts at the current month.
final statPeriodProvider = NotifierProvider<StatPeriodNotifier, StatPeriod>(
  StatPeriodNotifier.new,
);

class StatPeriodNotifier extends Notifier<StatPeriod> {
  @override
  StatPeriod build() => StatPeriod.containing(PeriodUnit.month, _now);

  DateTime get _now => ref.read(clockProvider).now();

  /// The current period of the new unit (Week / Month / Year tabs).
  void setUnit(PeriodUnit unit) {
    if (unit != state.unit) state = StatPeriod.containing(unit, _now);
  }

  void previous() => state = state.previous;

  /// Moves forward, but not past the current period.
  void next() {
    if (canGoNext) state = state.next;
  }

  /// True when the next period has already started (no future periods).
  bool get canGoNext => !state.next.start.isAfter(_now);
}

/// All numbers for the selected period and the 5 periods before it.
final statisticsProvider = Provider<AsyncValue<StatisticsData>>((ref) {
  final period = ref.watch(statPeriodProvider);
  final first = period.lastN(StatisticsData.chartLength).first;
  return ref
      .watch(periodTransactionsProvider(DateRange(first.start, period.end)))
      .whenData((items) => StatisticsData.build(period, items));
});
