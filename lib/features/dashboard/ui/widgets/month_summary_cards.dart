import 'package:flutter/material.dart';

import '../../../../core/format/date_format.dart';
import '../../../../core/format/money_format.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/amount_text.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/category_icon_tile.dart';
import '../../../../core/widgets/pill.dart';
import '../../../../core/widgets/progress_bar.dart';
import '../../domain/dashboard_data.dart';

/// The Income and Expenses cards side by side.
class IncomeExpenseCards extends StatelessWidget {
  const IncomeExpenseCards({super.key, required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final prevMonth = data.previous == null
        ? null
        : DateText.monthShort(data.previous!.month);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _StatCard(
              label: 'Income',
              amount: data.current.income,
              change: data.incomeChange,
              compareTo: prevMonth,
              icon: AppIcons.arrowDownLeft,
              foreground: c.income,
              background: c.incomeSoft,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              label: 'Expenses',
              amount: data.current.expense,
              change: data.expenseChange,
              compareTo: prevMonth,
              icon: AppIcons.arrowUpRight,
              foreground: c.expense,
              background: c.expenseSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.amount,
    required this.change,
    required this.compareTo,
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final String label;
  final int amount;
  final double? change;
  final String? compareTo;
  final AppIconData icon;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final change = this.change;
    final footStyle = AppText.small12.copyWith(color: c.textSecondary);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(
                icon: icon,
                foreground: foreground,
                background: background,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppText.label14.copyWith(color: c.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AmountText(amount, style: AppText.title21, showUnit: false),
          const SizedBox(height: 4),
          if (change == null || compareTo == null)
            Text(
              'UZS this month',
              style: AppText.small12Regular.copyWith(color: c.textTertiary),
            )
          else
            Row(
              children: [
                AppIcon(
                  change >= 0 ? AppIcons.trendUp : AppIcons.trendDown,
                  size: 14,
                  color: c.textSecondary,
                ),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    '${PercentFormat.value(change.abs(), decimals: 1)} '
                    'vs $compareTo',
                    style: footStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// "Saved this month" with the savings rate bar.
class SavingsCard extends StatelessWidget {
  const SavingsCard({super.key, required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final savings = data.current.savings;
    final rate = data.current.savingsRate;
    final change = data.savingsRateChange;
    final negative = savings < 0;
    final color = negative ? c.expense : c.savings;

    var foot = 'Income − Expenses';
    if (change != null && data.previous != null) {
      final pts = change.abs().toStringAsFixed(1);
      final month = DateText.month(data.previous!.month);
      foot += change >= 0
          ? ' · $pts pts higher than $month'
          : ' · $pts pts lower than $month';
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(
                icon: AppIcons.coins,
                foreground: c.savings,
                background: c.savingsSoft,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Saved this month',
                  style: AppText.label14.copyWith(color: c.textSecondary),
                ),
              ),
              if (rate != null && rate > 0)
                Pill.badge(
                  '${rate.round()}% of income',
                  foreground: c.savings,
                  background: c.savingsSoft,
                ),
            ],
          ),
          const SizedBox(height: 12),
          AmountText(
            savings,
            style: AppText.title26,
            color: color,
            unitStyle: AppText.label14Regular,
            unitGap: 6,
          ),
          const SizedBox(height: 12),
          ProgressBar(value: (rate ?? 0) / 100, color: color),
          const SizedBox(height: 12),
          Text(
            foot,
            style: AppText.small12Regular.copyWith(color: c.textTertiary),
          ),
        ],
      ),
    );
  }
}
