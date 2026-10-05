import 'package:flutter/material.dart';

import '../../../../core/format/date_format.dart';
import '../../../../core/format/money_format.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../domain/transaction_filter.dart';

/// "In · Out · Net" totals for the filtered list.
class InOutNetCard extends StatelessWidget {
  const InOutNetCard({super.key, required this.view});

  final TransactionListView view;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget column(String label, String value, Color color) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.small12Regular.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: AppText.body16Strong.copyWith(
                color: color,
                letterSpacing: -0.16,
              ),
            ),
          ),
        ],
      ),
    );
    Widget divider() => Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: c.divider,
    );

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          column('In', MoneyFormat.signed(view.income), c.income),
          divider(),
          column('Out', MoneyFormat.signed(-view.expense), c.textPrimary),
          divider(),
          column('Net', MoneyFormat.signed(view.net), c.savings),
        ],
      ),
    );
  }
}

/// "38 transactions ........ Newest first ⌄".
class CountAndSortRow extends StatelessWidget {
  const CountAndSortRow({
    super.key,
    required this.count,
    required this.sort,
    required this.onSort,
  });

  final int count;
  final SortOrder sort;
  final VoidCallback onSort;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = AppText.caption13Regular.copyWith(color: c.textSecondary);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$count ${count == 1 ? 'transaction' : 'transactions'}',
              style: style,
            ),
          ),
          Semantics(
            container: true,
            button: true,
            label: 'Sort: ${sort.label}',
            excludeSemantics: true,
            child: InkWell(
              onTap: onSort,
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 32),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(sort.label, style: style),
                    const SizedBox(width: 4),
                    AppIcon(
                      AppIcons.chevronDown,
                      size: 14,
                      color: c.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "TODAY · 30 SEP ............ +14 545 000".
class DayHeader extends StatelessWidget {
  const DayHeader({super.key, required this.group, required this.now});

  final DayGroup group;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final net = group.net;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                DateText.dayGroup(group.day, now: now).toUpperCase(),
                style: AppText.overline12.copyWith(color: c.textSecondary),
              ),
            ),
          ),
          Text(
            MoneyFormat.signed(net),
            style: AppText.caption13Strong.copyWith(
              color: net > 0 ? c.income : c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
