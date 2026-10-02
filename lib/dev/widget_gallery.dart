import 'package:flutter/material.dart';

import '../core/format/money_format.dart';
import '../core/icons/app_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../core/widgets/amount_text.dart';
import '../core/widgets/app_card.dart';
import '../core/widgets/app_chip.dart';
import '../core/widgets/app_icon.dart';
import '../core/widgets/buttons.dart';
import '../core/widgets/category_icon_tile.dart';
import '../core/widgets/pill.dart';
import '../core/widgets/progress_bar.dart';
import '../core/widgets/section_header.dart';
import '../core/widgets/segmented_tabs.dart';

/// Grid of every icon with its name.
class IconGallery extends StatelessWidget {
  const IconGallery({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Wrap(
      spacing: 4,
      runSpacing: 12,
      children: [
        for (final entry in AppIcons.all.entries)
          SizedBox(
            width: 70,
            child: Column(
              children: [
                AppIcon(entry.value, size: 24),
                const SizedBox(height: 4),
                Text(
                  entry.key,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.tiny11.copyWith(color: c.textTertiary),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Shared widgets put together like parts of the design boards.
class WidgetGallery extends StatefulWidget {
  const WidgetGallery({super.key});

  @override
  State<WidgetGallery> createState() => _WidgetGalleryState();
}

enum _Kind { expense, income }

enum _Period { week, month, year }

class _WidgetGalleryState extends State<WidgetGallery> {
  var _kind = _Kind.expense;
  var _period = _Period.month;
  var _filter = 'All';
  var _hidden = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header buttons.
        Row(
          children: [
            CircleIconButton(
              icon: AppIcons.close,
              semanticLabel: 'Close',
              onTap: () {},
            ),
            const Spacer(),
            CircleIconButton.raised(
              icon: AppIcons.search,
              semanticLabel: 'Search transactions',
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Tabs.
        SegmentedTabs(
          options: [
            SegmentOption(_Kind.expense, 'Expense', selectedColor: c.expense),
            SegmentOption(_Kind.income, 'Income', selectedColor: c.income),
          ],
          selected: _kind,
          onChanged: (v) => setState(() => _kind = v),
        ),
        const SizedBox(height: 12),
        SegmentedTabs(
          options: const [
            SegmentOption(_Period.week, 'Week'),
            SegmentOption(_Period.month, 'Month'),
            SegmentOption(_Period.year, 'Year'),
          ],
          selected: _period,
          onChanged: (v) => setState(() => _period = v),
        ),
        const SizedBox(height: 16),

        // Chips.
        ChipRow(
          padding: EdgeInsets.zero,
          children: [
            for (final f in ['All', 'Expenses', 'Income'])
              AppChip(
                label: f,
                selected: _filter == f,
                onTap: () => setState(() => _filter = f),
              ),
            AppChip(
              label: 'September',
              trailingIcon: AppIcons.chevronDown,
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AppChip(
              label: 'Today',
              leadingIcon: AppIcons.calendar,
              onTap: () {},
            ),
            AppChip(
              label: 'Humo',
              leadingIcon: AppIcons.card,
              trailingIcon: AppIcons.chevronDown,
              onTap: () {},
            ),
            AppChip(
              label: 'Add note',
              leadingIcon: AppIcons.pencil,
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Balance card with hide toggle.
        AppCard(
          radius: 24,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Current balance',
                      style: AppText.label14.copyWith(color: c.textSecondary),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(10, 0),
                    child: CircleIconButton(
                      icon: _hidden ? AppIcons.eyeOff : AppIcons.eye,
                      iconSize: 18,
                      color: c.textTertiary,
                      semanticLabel: _hidden ? 'Show balance' : 'Hide balance',
                      onTap: () => setState(() => _hidden = !_hidden),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              AmountText(
                12450000,
                hidden: _hidden,
                style: AppText.amount40,
                unitStyle: AppText.body17,
                unitGap: 8,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  Pill(_hidden ? 'Humo ••••' : 'Humo 6 400 000'),
                  Pill(_hidden ? 'Uzcard ••••' : 'Uzcard 4 200 000'),
                  Pill(_hidden ? 'Cash ••••' : 'Cash 1 850 000'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Income / Expenses cards.
        Row(
          children: [
            Expanded(
              child: _StatCardSample(
                label: 'Income',
                amount: 15500000,
                trend: '3.3% vs Aug',
                icon: AppIcons.arrowDownLeft,
                trendIcon: AppIcons.trendUp,
                foreground: c.income,
                background: c.incomeSoft,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCardSample(
                label: 'Expenses',
                amount: 3050000,
                trend: '28.7% vs Aug',
                icon: AppIcons.arrowUpRight,
                trendIcon: AppIcons.trendDown,
                foreground: c.expense,
                background: c.expenseSoft,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Savings card.
        AppCard(
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
                  Pill.badge(
                    '80% of income',
                    foreground: c.savings,
                    background: c.savingsSoft,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AmountText(
                12450000,
                style: AppText.title26,
                color: c.savings,
                unitStyle: AppText.label14.copyWith(fontSize: 14),
                unitGap: 6,
              ),
              const SizedBox(height: 12),
              const ProgressBar(value: 0.803),
              const SizedBox(height: 12),
              Text(
                'Income − Expenses · 8.8 pts higher than August',
                style: AppText.small12.copyWith(color: c.textTertiary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Savings rate bar with last month marker.
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                PercentFormat.value(80.3),
                style: AppText.title28.copyWith(color: c.savings),
              ),
              const SizedBox(height: 12),
              const ProgressBar(value: 0.803, height: 10, marker: 0.715),
              const SizedBox(height: 12),
              Text(
                'Marker shows August (71.5%)',
                style: AppText.small12.copyWith(color: c.textTertiary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Section header + category rows.
        SectionHeader(
          title: 'Where your money went',
          actionLabel: 'Details',
          onAction: () {},
        ),
        AppCard(
          child: Column(
            children: [
              for (final (i, row) in _categoryRows.indexed) ...[
                if (i > 0) Divider(height: 24, color: c.divider),
                Row(
                  children: [
                    CategoryIconTile(icon: row.$1, color: row.$2),
                    const SizedBox(width: 12),
                    Expanded(child: Text(row.$3, style: AppText.body15)),
                    AmountText(row.$4, showUnit: false),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Buttons.
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: 'Edit',
                icon: AppIcons.pencil,
                onPressed: () {},
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SecondaryButton(
                label: 'Duplicate',
                icon: AppIcons.copy,
                onPressed: () {},
              ),
            ),
          ],
        ),
        TextActionButton(
          label: 'Delete transaction',
          icon: AppIcons.trash,
          color: c.expense,
          onPressed: () {},
        ),
        const SizedBox(height: 8),
        PrimaryButton(
          label: 'Save expense · ${MoneyFormat.withCurrency(35000)}',
          onPressed: () {},
        ),
        const SizedBox(height: 8),
        const PrimaryButton(label: 'Disabled', onPressed: null),
      ],
    );
  }

  static const _categoryRows = [
    (AppIcons.cart, CategoryColor.green, 'Groceries', 820000),
    (AppIcons.alert, CategoryColor.amber, 'Emergency', 500000),
    (AppIcons.bag, CategoryColor.purple, 'Shopping', 470000),
    (AppIcons.car, CategoryColor.blue, 'Transportation', 410000),
  ];
}

class _StatCardSample extends StatelessWidget {
  const _StatCardSample({
    required this.label,
    required this.amount,
    required this.trend,
    required this.icon,
    required this.trendIcon,
    required this.foreground,
    required this.background,
  });

  final String label;
  final int amount;
  final String trend;
  final AppIconData icon;
  final AppIconData trendIcon;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
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
          Row(
            children: [
              AppIcon(trendIcon, size: 14, color: c.textSecondary),
              const SizedBox(width: 3),
              Text(
                trend,
                style: AppText.small12.copyWith(color: c.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
