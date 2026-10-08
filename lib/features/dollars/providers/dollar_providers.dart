import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/async/combine.dart';
import '../../../core/time/clock.dart';
import '../../../data/db/app_database.dart';
import '../../../data/models/currency.dart';
import '../../../data/providers/data_providers.dart';
import '../domain/dollar_stats.dart';

/// Dollars held now and what they cost.
final dollarStatsProvider = Provider<AsyncValue<DollarStats>>((ref) {
  final balances = ref.watch(balancesProvider(Currency.usd));
  final exchanges = ref.watch(exchangesProvider);
  return combine2(balances, exchanges).whenData(
    (v) => DollarStats.build(
      exchanges: v.$2,
      cents: v.$1.values.fold(0, (a, b) => a + b),
    ),
  );
});

/// The last saved CBU rate from before the current month started, to
/// show how the rate moved this month. Null when there is none.
final monthStartRateProvider = StreamProvider<ExchangeRateRow?>((ref) {
  final start = monthStart(ref.watch(clockProvider).now());
  return ref
      .watch(exchangeRateRepositoryProvider)
      .watchLatestBefore(Currency.usd, start);
});
