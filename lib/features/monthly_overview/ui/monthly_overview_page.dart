import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/date_format.dart';
import '../../../core/format/money_format.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/option_sheet.dart';
import '../../../core/widgets/pill.dart';
import '../../../core/widgets/progress_bar.dart';
import '../../../data/models/month_totals.dart';
import '../../../data/providers/data_providers.dart';
import '../domain/monthly_overview_data.dart';

/// Month by month income, expenses and savings for one year.
class MonthlyOverviewPage extends ConsumerStatefulWidget {
  const MonthlyOverviewPage({super.key});

  @override
  ConsumerState<MonthlyOverviewPage> createState() =>
      _MonthlyOverviewPageState();
}

class _MonthlyOverviewPageState extends ConsumerState<MonthlyOverviewPage> {
  late int _year = ref.read(clockProvider).now().year;

  Future<void> _pickYear(List<MonthTotals> all) async {
    final years = MonthlyOverviewData.years(
      all,
      ref.read(clockProvider).now().year,
    );
    final picked = await showOptionSheet<int>(
      context,
      title: 'Year',
      selected: _year,
      options: [for (final y in years) SheetOption(value: y, label: '$y')],
    );
    if (picked != null) setState(() => _year = picked);
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(monthTotalsProvider).value;
    final data = all == null ? null : MonthlyOverviewData.build(_year, all);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              year: _year,
              onBack: () => context.pop(),
              onYear: all == null ? null : () => _pickYear(all),
            ),
            Expanded(
              child: data == null
                  ? const SizedBox.shrink()
                  : data.isEmpty
                  ? _Empty(year: _year)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                      children: [
                        _SummaryCard(data: data),
                        const SizedBox(height: 14),
                        _LatestCard(item: data.latest),
                        if (data.earlier.isNotEmpty) ...[
                          const SizedBox(height: 22),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              'EARLIER MONTHS',
                              style: AppText.overline13.copyWith(
                                color: context.colors.textSecondary,
                              ),
                            ),
                          ),
                          for (final m in data.earlier) ...[
                            const SizedBox(height: 14),
                            _MonthCard(item: m),
                          ],
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.year,
    required this.onBack,
    required this.onYear,
  });

  final int year;
  final VoidCallback onBack;
  final VoidCallback? onYear;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Align(
                alignment: Alignment.centerLeft,
                child: CircleIconButton.raised(
                  icon: AppIcons.chevronLeft,
                  semanticLabel: 'Back',
                  onTap: onBack,
                ),
              ),
            ),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  'Monthly overview',
                  textAlign: TextAlign.center,
                  style: AppText.heading17,
                ),
              ),
            ),
            SizedBox(
              width: 100,
              child: Align(
                alignment: Alignment.centerRight,
                child: Semantics(
                  container: true,
                  button: true,
                  label: 'Year $year',
                  excludeSemantics: true,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      boxShadow: AppShadows.card(Theme.of(context).brightness),
                    ),
                    child: Material(
                      color: c.surface,
                      shape: const StadiumBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: onYear,
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$year', style: AppText.label14Strong),
                              const SizedBox(width: 4),
                              const AppIcon(AppIcons.chevronDown, size: 14),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "APRIL – SEPTEMBER 2026" with the totals of all shown months.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});

  final MonthlyOverviewData data;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final first = DateText.month(data.firstMonth);
    final last = DateText.monthYear(data.lastMonth);
    final title = data.firstMonth == data.lastMonth ? last : '$first – $last';
    final rate = data.averageRate;

    Widget cell(String label, String value, Color color) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.small12Regular.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(value, style: AppText.heading17.copyWith(color: color)),
      ],
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title.toUpperCase(),
            style: AppText.overline13.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: cell(
                  'Income',
                  MoneyFormat.amount(data.income),
                  c.income,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: cell(
                  'Expenses',
                  MoneyFormat.amount(data.expense),
                  c.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: cell(
                  'Savings',
                  MoneyFormat.amount(data.savings),
                  data.savings < 0 ? c.expense : c.savings,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: cell(
                  'Avg. savings rate',
                  rate == null ? '—' : PercentFormat.value(rate, decimals: 1),
                  c.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The newest month, big, with four tiles compared with the month before.
class _LatestCard extends StatelessWidget {
  const _LatestCard({required this.item});

  final MonthComparison item;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = item.month;
    final rate = m.savingsRate;

    Widget tile(String label, String value, Color color, String? change) =>
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.field),
          ),
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
                  value,
                  style: AppText.title20.copyWith(
                    fontSize: 18,
                    letterSpacing: -0.18,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              _Change(text: change),
            ],
          ),
        );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateText.monthYear(m.month),
                  style: AppText.title20.copyWith(
                    fontSize: 19,
                    letterSpacing: 0,
                  ),
                ),
              ),
              if (item.previous != null)
                Pill(
                  'vs ${DateText.month(item.previous!.month)}',
                  strong: true,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: tile(
                  'Income',
                  MoneyFormat.amount(m.income),
                  c.income,
                  _percent(item.incomeChange),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: tile(
                  'Expenses',
                  MoneyFormat.amount(m.expense),
                  c.textPrimary,
                  _percent(item.expenseChange),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: tile(
                  'Savings',
                  MoneyFormat.amount(m.savings),
                  m.savings < 0 ? c.expense : c.savings,
                  _percent(item.savingsChange),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: tile(
                  'Savings rate',
                  rate == null ? '—' : PercentFormat.value(rate, decimals: 1),
                  c.textPrimary,
                  item.rateChange == null
                      ? null
                      : PercentFormat.points(item.rateChange!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A smaller card for an earlier month.
class _MonthCard extends StatelessWidget {
  const _MonthCard({required this.item});

  final MonthComparison item;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = item.month;
    final rate = m.savingsRate;

    Widget column(String label, int value, Color color, double? change) =>
        Expanded(
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
                  MoneyFormat.amount(value),
                  style: AppText.label14Strong.copyWith(color: color),
                ),
              ),
              const SizedBox(height: 2),
              _Change(text: item.isFirst ? '—' : _percent(change)),
            ],
          ),
        );

    final prev = item.previous;
    final foot = prev == null
        ? 'First tracked month'
        : item.rateChange == null
        ? null
        : '${PercentFormat.points(item.rateChange!)} vs '
              '${DateText.monthShort(prev.month)}';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateText.month(m.month),
                  style: AppText.body16Strong,
                ),
              ),
              if (rate != null)
                Text(
                  '${PercentFormat.value(rate, decimals: 1)} saved',
                  style: AppText.caption13Strong.copyWith(color: c.savings),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              column('Income', m.income, c.income, item.incomeChange),
              const SizedBox(width: 8),
              column('Expenses', m.expense, c.textPrimary, item.expenseChange),
              const SizedBox(width: 8),
              column(
                'Savings',
                m.savings,
                m.savings < 0 ? c.expense : c.savings,
                item.savingsChange,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ProgressBar(
                  value: (rate ?? 0) / 100,
                  height: 6,
                  color: c.savings,
                ),
              ),
              if (foot != null) ...[
                const SizedBox(width: 10),
                Text(
                  foot,
                  style: AppText.small12Regular.copyWith(color: c.textTertiary),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// "+3.3%" with a small up or down arrow. No arrow for "±0.0%" or "—".
class _Change extends StatelessWidget {
  const _Change({required this.text});

  final String? text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = this.text;
    if (text == null) return const SizedBox(height: 16);
    final up = text.startsWith('+');
    final down = text.startsWith('−');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (up || down) ...[
          AppIcon(
            up ? AppIcons.trendUp : AppIcons.trendDown,
            size: 13,
            color: c.textTertiary,
          ),
          const SizedBox(width: 2),
        ],
        Text(text, style: AppText.small12.copyWith(color: c.textSecondary)),
      ],
    );
  }
}

String? _percent(double? change) =>
    change == null ? null : PercentFormat.change(change);

class _Empty extends StatelessWidget {
  const _Empty({required this.year});

  final int year;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'No transactions in $year yet.',
          textAlign: TextAlign.center,
          style: AppText.body15.copyWith(color: context.colors.textSecondary),
        ),
      ),
    );
  }
}
