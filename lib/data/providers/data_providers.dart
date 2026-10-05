import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/time/clock.dart';
import '../db/app_database.dart';
import '../models/month_totals.dart';
import '../models/transaction_details.dart';
import '../models/transaction_kind.dart';
import '../repositories/category_repository.dart';
import '../repositories/payment_method_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/transaction_repository.dart';

// ---- Core objects. Set up in `bootstrap.dart` (or in tests). ----

final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('Override databaseProvider at startup.'),
);

final clockProvider = Provider<Clock>((ref) => const SystemClock());

/// Settings as they were when the app started. Used for the first frame,
/// before [settingsProvider] has loaded.
final initialSettingsProvider = Provider<AppSettings>(
  (ref) => AppSettings.empty,
);

// ---- Repositories. ----

final transactionRepositoryProvider = Provider(
  (ref) => TransactionRepository(
    ref.watch(databaseProvider),
    ref.watch(clockProvider),
  ),
);

final categoryRepositoryProvider = Provider(
  (ref) => CategoryRepository(ref.watch(databaseProvider)),
);

final paymentMethodRepositoryProvider = Provider(
  (ref) => PaymentMethodRepository(ref.watch(databaseProvider)),
);

final settingsRepositoryProvider = Provider(
  (ref) => SettingsRepository(ref.watch(databaseProvider)),
);

// ---- Live data. Screens build their own views on top of these. ----

final settingsProvider = StreamProvider<AppSettings>(
  (ref) => ref.watch(settingsRepositoryProvider).watch(),
);

/// The live settings, or the ones read at startup until they load.
/// Never loading, so widgets can read it directly.
final currentSettingsProvider = Provider<AppSettings>((ref) {
  final live = ref.watch(settingsProvider);
  return live.hasValue ? live.requireValue : ref.watch(initialSettingsProvider);
});

/// Active categories of one kind, in the user's order.
final categoriesProvider =
    StreamProvider.family<List<CategoryRow>, TransactionKind>(
      (ref, kind) => ref.watch(categoryRepositoryProvider).watchAll(kind: kind),
    );

/// Active payment methods, in the user's order.
final paymentMethodsProvider = StreamProvider<List<PaymentMethodRow>>(
  (ref) => ref.watch(paymentMethodRepositoryProvider).watchAll(),
);

/// Transactions in the month that contains the given date, newest first.
///
/// Pass a stable date (like the month start), not the current time:
/// each different date is a separate provider.
final monthTransactionsProvider =
    StreamProvider.family<List<TransactionDetails>, DateTime>((ref, month) {
      final start = monthStart(month);
      return ref
          .watch(transactionRepositoryProvider)
          .watchBetween(start, nextMonthStart(start));
    });

/// The newest transactions, for the "Recent" block on the Dashboard.
final recentTransactionsProvider = StreamProvider<List<TransactionDetails>>(
  (ref) => ref.watch(transactionRepositoryProvider).watchRecent(),
);

/// Income and expenses per month, oldest first.
final monthTotalsProvider = StreamProvider<List<MonthTotals>>(
  (ref) => ref.watch(transactionRepositoryProvider).watchMonthTotals(),
);

/// Balance of each payment method, by method id.
final balancesProvider = StreamProvider<Map<int, int>>(
  (ref) => ref.watch(transactionRepositoryProvider).watchBalances(),
);

/// One transaction, or null when it does not exist.
final transactionProvider = StreamProvider.family<TransactionDetails?, int>(
  (ref, id) => ref.watch(transactionRepositoryProvider).watchById(id),
);
