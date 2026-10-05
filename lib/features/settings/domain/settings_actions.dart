import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/money_format.dart';
import '../../../core/time/clock.dart';
import '../../../data/providers/data_providers.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../statistics/providers/statistics_providers.dart';
import '../../transactions/providers/transactions_providers.dart';

/// Saves the number style and redraws every amount on screen.
Future<void> applyNumberStyle(WidgetRef ref, NumberStyle style) async {
  MoneyFormat.style = style;
  await ref.read(settingsRepositoryProvider).setNumberStyle(style);
  rebuildAllWidgets();
}

/// Saves the month start day and recalculates everything that depends
/// on where a month begins.
Future<void> applyMonthStartDay(WidgetRef ref, int day) async {
  MonthCycle.startDay = day;
  await ref.read(settingsRepositoryProvider).setMonthStartDay(day);
  ref
    ..invalidate(monthTotalsProvider)
    ..invalidate(monthTransactionsProvider)
    ..invalidate(selectedMonthProvider)
    ..invalidate(statPeriodProvider)
    ..invalidate(transactionFilterProvider);
  rebuildAllWidgets();
}

/// Marks every widget for a rebuild, keeping all state. Needed after a
/// change to a global format, which widgets do not watch.
void rebuildAllWidgets() {
  void visit(Element e) {
    e.markNeedsBuild();
    e.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(visit);
}
