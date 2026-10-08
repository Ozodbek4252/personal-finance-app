import 'dart:async';

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
import '../../../core/widgets/charts/line_chart.dart';
import '../../../core/widgets/section_header.dart';
import '../../../data/models/currency.dart';
import '../../../data/models/display_style.dart';
import '../../../data/providers/data_providers.dart';
import '../../../router.dart';
import '../../transactions/domain/transaction_filter.dart';
import '../../transactions/providers/transactions_providers.dart';
import '../../transactions/ui/widgets/exchange_tile.dart';
import '../domain/dollar_stats.dart';
import '../domain/rate_history.dart';
import '../providers/dollar_providers.dart';

/// "Dollar balance": the dollars saved, what they cost, how the rate
/// moved, where they are and the latest exchanges.
class DollarBalancePage extends ConsumerStatefulWidget {
  const DollarBalancePage({super.key});

  @override
  ConsumerState<DollarBalancePage> createState() => _DollarBalancePageState();
}

class _DollarBalancePageState extends ConsumerState<DollarBalancePage> {
  /// The design shows the three newest exchanges.
  static const _recentCount = 3;

  @override
  void initState() {
    super.initState();
    // Fill in missing months for the chart. Without internet the chart
    // shows the months it has.
    unawaited(ref.read(rateServiceProvider).fillHistory());
  }

  void _showAllExchanges() {
    ref
        .read(transactionFilterProvider.notifier)
        .apply(
          const TransactionFilter(period: null, type: TypeFilter.exchanges),
        );
    context.go(Routes.transactions);
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(dollarStatsProvider).value ?? DollarStats.empty;
    final rate = ref.watch(usdRateProvider);
    final methods = ref.watch(dollarMethodsProvider).value ?? const [];
    final balances =
        ref.watch(balancesProvider(Currency.usd)).value ?? const {};
    final exchanges = ref.watch(exchangesProvider).value ?? const [];
    final history = RateHistory.monthly(
      ref.watch(rateHistoryProvider).value ?? const [],
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onBack: () => context.pop(),
              onConvert: () => context.push(Routes.buyDollars),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                children: [
                  _HoldingCard(cents: stats.cents, rate: rate?.value),
                  const SizedBox(height: 16),
                  _CostCard(stats: stats, rate: rate?.value),
                  const SizedBox(height: 16),
                  _RateChartCard(history: history),
                  const SizedBox(height: 16),
                  const SectionHeader(title: 'Where it is'),
                  const SizedBox(height: 4),
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Column(
                      children: [
                        for (final (i, m) in methods.indexed)
                          _MethodRow(
                            name: m.name,
                            icon: m.icon,
                            cents: balances[m.id] ?? 0,
                            showDivider: i > 0,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionHeader(
                    title: 'Exchanges',
                    actionLabel: exchanges.isEmpty ? null : 'All',
                    onAction: exchanges.isEmpty ? null : _showAllExchanges,
                  ),
                  const SizedBox(height: 4),
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: exchanges.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(
                              'No exchanges yet. Tap Buy USD to save in '
                              'dollars.',
                              style: AppText.label14Regular.copyWith(
                                color: context.colors.textSecondary,
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              for (final (i, e)
                                  in exchanges.take(_recentCount).indexed)
                                ExchangeTile(
                                  item: e,
                                  timeText: '',
                                  subtitle:
                                      '${DateText.dayMonth(e.occurredAt)}'
                                      ' · rate ${MoneyFormat.rate(e.exchange.rate)}',
                                  showDivider: i > 0,
                                  onTap: () =>
                                      context.push(Routes.exchangeDetail(e.id)),
                                ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          label: 'Buy USD',
                          icon: AppIcons.exchange,
                          onPressed: () => context.push(Routes.buyDollars),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SecondaryButton(
                          label: 'Sell USD',
                          icon: AppIcons.exchange,
                          onPressed: stats.cents > 0
                              ? () => context.push(Routes.sellDollars)
                              : null,
                        ),
                      ),
                    ],
                  ),
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
  const _Header({required this.onBack, required this.onConvert});

  final VoidCallback onBack;
  final VoidCallback onConvert;

  @override
  Widget build(BuildContext context) {
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
                  'Dollar balance',
                  textAlign: TextAlign.center,
                  style: AppText.heading17,
                ),
              ),
            ),
            SizedBox(
              width: 100,
              child: Align(
                alignment: Alignment.centerRight,
                child: CircleIconButton.raised(
                  icon: AppIcons.exchange,
                  semanticLabel: 'Convert',
                  onTap: onConvert,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "You have $500.00 ≈ 6 325 000 UZS at today's rate".
class _HoldingCard extends StatelessWidget {
  const _HoldingCard({required this.cents, required this.rate});

  final int cents;
  final double? rate;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final rate = this.rate;
    return AppCard(
      padding: const EdgeInsets.all(20),
      radius: AppRadius.cardLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You have',
            style: AppText.label14.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              MoneyFormat.dollars(cents),
              maxLines: 1,
              style: AppText.amount40,
            ),
          ),
          if (rate != null && cents != 0) ...[
            const SizedBox(height: 8),
            Text(
              '≈ ${MoneyFormat.withCurrency((cents * rate / 100).round())} '
              'at today’s rate',
              style: AppText.body15Regular.copyWith(color: c.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

/// Average buy rate, today's rate, what was paid and the value change.
class _CostCard extends StatelessWidget {
  const _CostCard({required this.stats, required this.rate});

  final DollarStats stats;
  final double? rate;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final average = stats.averageRate;
    final rate = this.rate;
    final change = rate == null ? null : stats.valueChange(rate);
    final tiles = [
      _Tile(
        'Average buy rate',
        average == null ? '—' : MoneyFormat.amount(average.round()),
      ),
      _Tile('Today’s rate', rate == null ? '—' : MoneyFormat.rate(rate)),
      _Tile(
        'You paid',
        average == null ? '—' : MoneyFormat.withCurrency(stats.paid),
      ),
      _Tile(
        'Value change',
        change == null
            ? '—'
            : '${MoneyFormat.signed(change)}${MoneyFormat.nbsp}UZS',
        color: change == null || change == 0
            ? null
            : change > 0
            ? c.income
            : c.expense,
      ),
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var r = 0; r < 2; r++) ...[
            if (r > 0) const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: tiles[r * 2]),
                  const SizedBox(width: 8),
                  Expanded(child: tiles[r * 2 + 1]),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            'Value change = what your dollars are worth today minus what '
            'you paid.',
            style: AppText.small12Regular.copyWith(color: c.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.label, this.value, {this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.small12Regular.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(value, style: AppText.body16Strong.copyWith(color: color)),
        ],
      ),
    );
  }
}

/// "USD rate · 6 months" with the change this month and since the start.
class _RateChartCard extends StatelessWidget {
  const _RateChartCard({required this.history});

  final List<MonthRate> history;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final parts = <String>[];
    if (history.length >= 2) {
      final last = history.last.rate;
      final before = history[history.length - 2].rate;
      parts
        ..add(
          '${PercentFormat.change(RateHistory.change(before, last))} '
          'this month',
        )
        ..add(
          '${PercentFormat.change(RateHistory.change(history.first.rate, last))} '
          'since ${DateText.month(history.first.month)}',
        );
    }
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title:
                'USD rate · ${history.length < 2 ? 'last months' : '${history.length} months'}',
            padding: EdgeInsets.zero,
          ),
          if (parts.isNotEmpty)
            Text(
              parts.join(' · '),
              style: AppText.caption13Regular.copyWith(color: c.textSecondary),
            ),
          const SizedBox(height: 10),
          if (history.length < 2)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'The chart fills in when the app is online.',
                textAlign: TextAlign.center,
                style: AppText.label14Regular.copyWith(color: c.textTertiary),
              ),
            )
          else
            LineChart(
              points: [
                for (final p in history)
                  LinePoint(
                    label: DateText.monthShort(p.month),
                    value: p.rate.round(),
                  ),
              ],
              color: c.accent,
              ticks: RateHistory.ticks(history.map((p) => p.rate)),
              tickFormat: (v) => MoneyFormat.amount(v.round()),
              labelWidth: 40,
              showArea: false,
              height: 150,
              semanticLabel: 'USD to UZS rate, last ${history.length} months',
            ),
        ],
      ),
    );
  }
}

class _MethodRow extends StatelessWidget {
  const _MethodRow({
    required this.name,
    required this.icon,
    required this.cents,
    required this.showDivider,
  });

  final String name;
  final AppIconData icon;
  final int cents;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(top: BorderSide(color: c.divider))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: AppIcon(icon, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(name, style: AppText.body15)),
            Text(MoneyFormat.dollars(cents), style: AppText.body15Strong),
          ],
        ),
      ),
    );
  }
}
