import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/format/date_format.dart';
import '../../../../core/format/money_format.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/amount_text.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/category_icon_tile.dart';
import '../../../../core/widgets/charts/month_bar_chart.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/stacked_bar.dart';
import '../../../../data/models/display_style.dart';
import '../../../../router.dart';
import '../../domain/dashboard_data.dart';

/// "Where your money went": split bar and the top 4 categories.
class SpendingByCategorySection extends StatelessWidget {
  const SpendingByCategorySection({super.key, required this.data});

  final DashboardData data;

  static const _shownRows = 4;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final brightness = Theme.of(context).brightness;
    final categories = data.categories;
    final rest = categories.skip(_shownRows).toList();
    final restTotal = rest.fold(0, (sum, s) => sum + s.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Where your money went',
          actionLabel: 'Details',
          onAction: () => context.go(Routes.statistics),
        ),
        const SizedBox(height: 4),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StackedBar(
                semanticLabel: 'Spending split by category',
                segments: [
                  for (final s in categories)
                    (s.amount, s.category.color.resolve(brightness)),
                ],
              ),
              const SizedBox(height: 16),
              for (final (i, s) in categories.take(_shownRows).indexed)
                _CategoryRow(spend: s, showDivider: i > 0),
              if (rest.isNotEmpty)
                InkWell(
                  onTap: () => context.go(Routes.statistics),
                  child: Container(
                    margin: const EdgeInsets.only(top: 12),
                    constraints: const BoxConstraints(minHeight: 44),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: c.divider)),
                    ),
                    child: Text(
                      '${rest.length} more '
                      '${rest.length == 1 ? 'category' : 'categories'} · '
                      '${MoneyFormat.withCurrency(restTotal)}',
                      style: AppText.label14.copyWith(color: c.textSecondary),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.spend, required this.showDivider});

  final CategorySpend spend;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: EdgeInsets.only(top: showDivider ? 12 : 0),
      padding: EdgeInsets.only(top: showDivider ? 12 : 4),
      decoration: BoxDecoration(
        border: showDivider ? Border(top: BorderSide(color: c.divider)) : null,
      ),
      child: Row(
        children: [
          CategoryIconTile(
            icon: spend.category.icon,
            color: spend.category.color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              spend.category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.body15,
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '${spend.percent.round()}%',
              textAlign: TextAlign.right,
              style: AppText.caption13Regular.copyWith(color: c.textTertiary),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 92,
            child: Align(
              alignment: Alignment.centerRight,
              child: AmountText(spend.amount, showUnit: false),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Spending trend": this month's spending and a 6-month bar chart.
class SpendingTrendSection extends StatelessWidget {
  const SpendingTrendSection({super.key, required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final change = data.expenseChange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Spending trend',
          actionLabel: 'Monthly',
          onAction: () => context.push(Routes.monthlyOverview),
        ),
        const SizedBox(height: 4),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spent in ${DateText.month(data.month)}',
                          style: AppText.caption13Regular.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AmountText(
                          data.current.expense,
                          style: AppText.title20,
                          unitStyle: AppText.caption13,
                        ),
                      ],
                    ),
                  ),
                  if (change != null && data.previous != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: c.surfaceMuted,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppIcon(
                            change >= 0 ? AppIcons.trendUp : AppIcons.trendDown,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${change.abs().round()}% vs '
                            '${DateText.monthShort(data.previous!.month)}',
                            style: AppText.caption13Strong,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              MonthBarChart(
                highlightColor: c.expense,
                bars: [
                  for (final m in data.trend)
                    MonthBar(
                      label: DateText.monthShort(m.month),
                      value: m.expense,
                      highlighted: m.month == data.month,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Insights": up to three short sentences about the month.
class InsightsSection extends StatelessWidget {
  const InsightsSection({super.key, required this.insights});

  final List<Insight> insights;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final brightness = Theme.of(context).brightness;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Insights'),
        const SizedBox(height: 4),
        AppCard(
          child: Column(
            children: [
              for (final (i, insight) in insights.indexed)
                Container(
                  margin: EdgeInsets.only(top: i > 0 ? 12 : 0),
                  padding: EdgeInsets.only(top: i > 0 ? 12 : 0),
                  decoration: BoxDecoration(
                    border: i > 0
                        ? Border(top: BorderSide(color: c.divider))
                        : null,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _insightTile(insight, c, brightness),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                for (final span in insight.spans)
                                  TextSpan(
                                    text: span.text,
                                    style: span.bold
                                        ? AppText.label14Strong
                                        : null,
                                  ),
                              ],
                            ),
                            style: AppText.label14Regular.copyWith(
                              height: 1.45,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _insightTile(Insight insight, AppColors c, Brightness brightness) {
    final color = insight.color;
    if (color != null) {
      return CategoryIconTile(
        icon: insight.icon,
        color: color,
        size: 32,
        iconSize: 17,
      );
    }
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.savingsSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: AppIcon(insight.icon, size: 17, color: c.savings),
    );
  }
}
