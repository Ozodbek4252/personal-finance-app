import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format/money_format.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/amount_text.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/category_chip.dart';
import '../../../../core/widgets/charts/donut_chart.dart';
import '../../../../core/widgets/charts/grouped_bar_chart.dart';
import '../../../../core/widgets/charts/line_chart.dart';
import '../../../../core/widgets/charts/month_bar_chart.dart';
import '../../../../core/widgets/progress_bar.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../data/models/display_style.dart';
import '../../../../data/models/transaction_kind.dart';
import '../../../../data/providers/data_providers.dart';
import '../../domain/stat_period.dart';
import '../../domain/statistics_data.dart';

/// "Income − Expenses = Savings" and the savings rate bar.
class StatSavingsCard extends StatelessWidget {
  const StatSavingsCard({super.key, required this.data});

  final StatisticsData data;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cur = data.current;
    final rate = cur.savingsRate;
    final prevRate = data.previous.savingsRate;
    final change = data.savingsRateChange;
    final negative = cur.savings < 0;

    Widget part(String label, int value, Color color) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.small12Regular.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              MoneyFormat.amount(value),
              maxLines: 1,
              style: AppText.body16Strong.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
    Widget sign(String s) => Padding(
      padding: const EdgeInsets.fromLTRB(3, 14, 3, 0),
      child: Text(
        s,
        style: AppText.body17.copyWith(fontSize: 18, color: c.textTertiary),
      ),
    );

    String? foot;
    if (prevRate != null && change != null) {
      foot =
          'Marker shows ${data.previous.period.asPrevious} '
          '(${PercentFormat.value(prevRate, decimals: 1)}) · '
          '${PercentFormat.points(change)} ${data.period.thisName}';
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'SAVINGS',
            style: AppText.overline13.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              part('Income', cur.income, c.income),
              sign('−'),
              part('Expenses', cur.expense, c.textPrimary),
              sign('='),
              part('Savings', cur.savings, negative ? c.expense : c.savings),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: c.divider),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Savings rate',
                      style: AppText.caption13Regular.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rate == null
                          ? '—'
                          : PercentFormat.value(rate, decimals: 1),
                      style: AppText.title28.copyWith(
                        fontSize: 32,
                        color: negative ? c.expense : c.savings,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'Savings ÷ Income × 100',
                  style: AppText.caption13Regular.copyWith(
                    color: c.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ProgressBar(
            value: (rate ?? 0) / 100,
            height: 10,
            color: c.savings,
            marker: prevRate == null ? null : prevRate / 100,
          ),
          if (foot != null) ...[
            const SizedBox(height: 14),
            Text(
              foot,
              style: AppText.small12Regular.copyWith(color: c.textTertiary),
            ),
          ],
        ],
      ),
    );
  }
}

/// Donut chart and legend of spending per category.
class SpendingByCategoryCard extends StatelessWidget {
  const SpendingByCategoryCard({super.key, required this.data});

  final StatisticsData data;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final brightness = Theme.of(context).brightness;
    final cats = data.categories;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'Spending by category',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 12),
          if (cats.isEmpty)
            _EmptyNote(text: 'No spending ${data.period.inName}.')
          else ...[
            Center(
              child: DonutChart(
                semanticLabel: 'Spending by category donut chart',
                segments: [
                  for (final s in cats)
                    (s.amount, s.category.color.resolve(brightness)),
                ],
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total spent',
                      style: AppText.small12Regular.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      MoneyFormat.amount(data.current.expense),
                      style: AppText.title20,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      MoneyFormat.currency,
                      style: AppText.small12Regular.copyWith(
                        color: c.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            for (final (i, s) in cats.indexed)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: i > 0
                      ? Border(top: BorderSide(color: c.divider))
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: s.category.color.resolve(brightness),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body15,
                      ),
                    ),
                    SizedBox(
                      width: 44,
                      child: Text(
                        '${s.percent.round()}%',
                        textAlign: TextAlign.right,
                        style: AppText.caption13Regular.copyWith(
                          color: c.textTertiary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 88,
                      child: Text(
                        MoneyFormat.amount(s.amount),
                        textAlign: TextAlign.right,
                        style: AppText.body15Strong,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Income and expense bars for the last 6 periods.
class IncomeVsExpensesCard extends StatelessWidget {
  const IncomeVsExpensesCard({super.key, required this.data});

  final StatisticsData data;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final maxValue = data.history.fold(
      0,
      (m, p) => [m, p.income, p.expense].reduce((a, b) => a > b ? a : b),
    );
    final step = niceStep(maxValue / 4);
    final ticks = [for (var t = 0.0; t <= maxValue; t += step) t];

    Widget legend(String label, Color color) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppText.caption13Regular.copyWith(color: c.textSecondary),
        ),
      ],
    );

    final lastThree = data.history.skip(data.history.length - 3);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'Income vs expenses',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 12),
          if (maxValue == 0)
            const _EmptyNote(text: 'No income or expenses yet.')
          else ...[
            Row(
              children: [
                legend('Income', c.income),
                const SizedBox(width: 16),
                legend('Expenses', c.expense),
              ],
            ),
            const SizedBox(height: 12),
            GroupedBarChart(
              semanticLabel: 'Income versus expenses by period',
              firstColor: c.income,
              secondColor: c.expense,
              ticks: ticks,
              groups: [
                for (final p in data.history)
                  BarGroup(
                    label: p.period.shortLabel,
                    first: p.income,
                    second: p.expense,
                    highlighted: p.period == data.period,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: c.divider),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final p in lastThree)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.period.mediumLabel,
                          style: AppText.small12Regular.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          MoneyFormat.compact(p.income, showSign: true),
                          style: AppText.caption13Strong.copyWith(
                            color: c.income,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          MoneyFormat.compact(-p.expense),
                          style: AppText.caption13Strong,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Line chart of spending with the average, and "Decreasing" or
/// "Increasing" compared with the previous period.
class SpendingTrendCard extends StatelessWidget {
  const SpendingTrendCard({super.key, required this.data});

  final StatisticsData data;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final values = data.history.map((p) => p.expense).toList();
    final min = values.reduce((a, b) => a < b ? a : b).toDouble();
    final max = values.reduce((a, b) => a > b ? a : b).toDouble();
    final step = niceStep((max - min) / 2);
    final low = (min / step).floorToDouble() * step;
    var high = (max / step).ceilToDouble() * step;
    if (high == low) high += step;
    final ticks = [for (var t = low; t <= high + 1; t += step) t];
    final change = data.expenseChange;
    final unitName = switch (data.period.unit) {
      PeriodUnit.week => 'Weekly',
      PeriodUnit.month => 'Monthly',
      PeriodUnit.year => 'Yearly',
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: '$unitName spending trend',
            padding: EdgeInsets.zero,
          ),
          if (max == 0)
            _EmptyNote(
              text: 'No spending in the last 6 ${data.period.unit.name}s.',
            )
          else ...[
            if (change != null) ...[
              Row(
                children: [
                  _TrendPill(
                    up: change > 0,
                    text: change > 0 ? 'Increasing' : 'Decreasing',
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '${PercentFormat.value(change.abs(), decimals: 1)} '
                      '${change > 0 ? 'more' : 'less'} than '
                      '${data.previous.period.asPrevious}',
                      style: AppText.caption13Regular.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            LineChart(
              semanticLabel: '$unitName spending trend',
              color: c.expense,
              ticks: ticks,
              average: data.averageExpense,
              points: [
                for (final p in data.history)
                  LinePoint(label: p.period.shortLabel, value: p.expense),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 16,
                  child: CustomPaint(
                    size: const Size(16, 2),
                    painter: _DashPainter(c.textTertiary),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '6-${data.period.unit.name} average · '
                    '${MoneyFormat.withCurrency(_roundThousand(data.averageExpense))}',
                    style: AppText.small12Regular.copyWith(
                      color: c.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Bar chart of one category over the last 6 periods, with category
/// chips to switch.
class CategoryTrendCard extends ConsumerStatefulWidget {
  const CategoryTrendCard({super.key, required this.data});

  final StatisticsData data;

  @override
  ConsumerState<CategoryTrendCard> createState() => _CategoryTrendCardState();
}

class _CategoryTrendCardState extends ConsumerState<CategoryTrendCard> {
  int? _selectedId;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final data = widget.data;
    final ordered =
        ref.watch(categoriesProvider(TransactionKind.expense)).value ??
        const [];
    final cats = data.trendCategories(ordered);
    if (cats.isEmpty) return const SizedBox.shrink();
    final selected = cats.firstWhere(
      (cat) => cat.id == _selectedId,
      orElse: () => cats.first,
    );
    final history = data.categoryHistory(selected.id);
    final current = history.last;
    final previous = history[history.length - 2];
    final change = previous == 0 ? null : (current - previous) / previous * 100;
    final average = (history.reduce((a, b) => a + b) / history.length).round();
    final count = data.categoryCount(selected.id);
    final color = selected.color.resolve(Theme.of(context).brightness);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'Category trend',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 12),
          ChipRow(
            padding: EdgeInsets.zero,
            children: [
              for (final cat in cats)
                CategoryChip(
                  category: cat,
                  selected: cat.id == selected.id,
                  onTap: () => setState(() => _selectedId = cat.id),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${selected.name} ${data.period.inName}',
                      style: AppText.caption13Regular.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AmountText(
                      current,
                      style: AppText.title22,
                      unitStyle: AppText.caption13,
                    ),
                  ],
                ),
              ),
              if (change != null)
                _TrendPill(
                  up: change > 0,
                  text:
                      '${change.abs().round()}% vs '
                      '${data.previous.period.shortLabel}',
                ),
            ],
          ),
          const SizedBox(height: 12),
          MonthBarChart(
            highlightColor: color,
            maxBarHeight: 96,
            bars: [
              for (final (i, p) in data.history.indexed)
                MonthBar(
                  label: p.period.shortLabel,
                  value: history[i],
                  highlighted: p.period == data.period,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '6-${data.period.unit.name} average · '
            '${MoneyFormat.withCurrency(_roundThousand(average))} · '
            '$count ${count == 1 ? 'transaction' : 'transactions'} '
            '${data.period.thisName}',
            style: AppText.small12Regular.copyWith(color: c.textTertiary),
          ),
        ],
      ),
    );
  }
}

/// Grey pill with a trend arrow, like "18% vs Aug".
class _TrendPill extends StatelessWidget {
  const _TrendPill({required this.up, required this.text});

  final bool up;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(up ? AppIcons.trendUp : AppIcons.trendDown, size: 14),
          const SizedBox(width: 4),
          Text(text, style: AppText.caption13Strong),
        ],
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppText.label14Regular.copyWith(
          color: context.colors.textTertiary,
        ),
      ),
    );
  }
}

/// Short dashed line for the "average" legend.
class _DashPainter extends CustomPainter {
  _DashPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    for (var x = 0.0; x < size.width; x += 6) {
      canvas.drawLine(Offset(x, 1), Offset(x + 3, 1), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

/// Averages are shown rounded to 1 000, like the design ("339 000").
int _roundThousand(int v) => (v / 1000).round() * 1000;
