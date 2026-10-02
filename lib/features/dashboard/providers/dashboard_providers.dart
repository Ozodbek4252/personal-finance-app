import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/async/combine.dart';
import '../../../core/time/clock.dart';
import '../../../data/db/app_database.dart';
import '../../../data/providers/data_providers.dart';
import '../domain/dashboard_data.dart';

/// The month shown on the Dashboard. Starts at the current month.
final selectedMonthProvider = NotifierProvider<SelectedMonth, DateTime>(
  SelectedMonth.new,
);

class SelectedMonth extends Notifier<DateTime> {
  @override
  DateTime build() => monthStart(ref.watch(clockProvider).now());

  void select(DateTime month) => state = monthStart(month);
}

/// Months the user can pick: from the first month with data up to the
/// current month, newest first.
final selectableMonthsProvider = Provider<List<DateTime>>((ref) {
  final now = monthStart(ref.watch(clockProvider).now());
  final totals = ref.watch(monthTotalsProvider).value ?? const [];
  var first = totals.isEmpty ? now : totals.first.month;
  if (first.isAfter(now)) first = now;
  return [
    for (var m = now; !m.isBefore(first); m = DateTime(m.year, m.month - 1)) m,
  ];
});

final dashboardProvider = Provider<AsyncValue<DashboardData>>((ref) {
  final month = ref.watch(selectedMonthProvider);
  final current = ref.watch(monthTransactionsProvider(month));
  final previous = ref.watch(
    monthTransactionsProvider(DateTime(month.year, month.month - 1)),
  );
  final totals = ref.watch(monthTotalsProvider);

  return combine3(current, previous, totals).whenData(
    (v) => DashboardData.build(
      month: month,
      monthTransactions: v.$1,
      previousTransactions: v.$2,
      allMonths: v.$3,
    ),
  );
});

/// One payment method with its balance, for the chips on the balance card.
typedef MethodBalance = ({PaymentMethodRow method, int balance});

class BalanceSummary {
  const BalanceSummary({
    required this.total,
    required this.methods,
    required this.hidden,
  });

  final int total;

  /// Methods with money on them, biggest balance first.
  final List<MethodBalance> methods;

  /// The user tapped "Hide balance".
  final bool hidden;
}

final balanceSummaryProvider = Provider<AsyncValue<BalanceSummary>>((ref) {
  final balances = ref.watch(balancesProvider);
  final methods = ref.watch(paymentMethodsProvider);
  final hidden = ref.watch(currentSettingsProvider).balanceHidden;

  return combine2(balances, methods).whenData((v) {
    final (byId, list) = v;
    final withMoney = [
      for (final m in list)
        if ((byId[m.id] ?? 0) != 0) (method: m, balance: byId[m.id]!),
    ]..sort((a, b) => b.balance.compareTo(a.balance));
    return BalanceSummary(
      // Archived methods still hold money, so sum all balances.
      total: byId.values.fold(0, (a, b) => a + b),
      methods: withMoney,
      hidden: hidden,
    );
  });
});
