import 'package:flutter/material.dart';

import '../../../../core/format/date_format.dart';
import '../../../../core/format/money_format.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/amount_text.dart';
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

/// "4 results for “taxi” ........ −148 000 UZS".
class ResultsHeader extends StatelessWidget {
  const ResultsHeader({super.key, required this.view, required this.query});

  final TransactionListView view;
  final String query;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final n = view.items.length;
    final q = query.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$n ${n == 1 ? 'result' : 'results'}',
                    style: AppText.label14Strong.copyWith(color: c.textPrimary),
                  ),
                  if (q.isNotEmpty) TextSpan(text: ' for “$q”'),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.label14Regular.copyWith(color: c.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          AmountText(
            view.net,
            signed: true,
            style: AppText.label14Strong.copyWith(letterSpacing: -0.14),
          ),
        ],
      ),
    );
  }
}

/// Centered message when nothing is found, with optional buttons.
class EmptyResults extends StatelessWidget {
  const EmptyResults({
    super.key,
    required this.title,
    required this.message,
    this.onClearFilters,
    this.onSearchAllTime,
  });

  final String title;
  final String message;
  final VoidCallback? onClearFilters;
  final VoidCallback? onSearchAllTime;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.surfaceMuted,
              borderRadius: BorderRadius.circular(22),
            ),
            child: AppIcon(
              AppIcons.search,
              size: 30,
              strokeWidth: 1.6,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppText.title20.copyWith(fontSize: 19, letterSpacing: 0),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.body15Regular.copyWith(
                color: c.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          if (onClearFilters != null || onSearchAllTime != null) ...[
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onClearFilters != null)
                  _SmallButton(
                    label: 'Clear filters',
                    onPressed: onClearFilters!,
                  ),
                if (onSearchAllTime != null)
                  _SmallButton(
                    label: 'Search all time',
                    onPressed: onSearchAllTime!,
                    filled: true,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// 44 px button used in the empty results message.
class _SmallButton extends StatelessWidget {
  const _SmallButton({
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: filled ? BorderSide.none : BorderSide(color: c.divider),
    );
    return Semantics(
      container: true,
      button: true,
      child: Material(
        color: filled ? c.primary : c.surface,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          customBorder: shape,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            // No alignment here: it would stretch the button to full width.
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppText.label14Strong.copyWith(
                    color: filled ? c.onPrimary : c.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
