import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/format/date_format.dart';
import '../../../../core/format/money_format.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/amount_text.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../data/providers/data_providers.dart';
import '../../../../data/rates/rate_service.dart';
import '../../../../router.dart';
import '../../../dollars/providers/dollar_providers.dart';
import '../../providers/dashboard_providers.dart';

/// The filled indigo card at the top of Home: the so'm balance, the
/// dollars as a second line, everything together, and today's rate
/// with a "Convert" button.
class BalanceCard extends ConsumerWidget {
  const BalanceCard({super.key});

  /// The design names the three biggest methods.
  static const _maxNames = 3;

  /// White text on the indigo card, at the design's opacities.
  static const _soft = Color(0xD1FFFFFF); // 82%
  static const _unit = Color(0xBFFFFFFF); // 75%
  static const _faint = Color(0xB8FFFFFF); // 72%
  static const _row = Color(0x1FFFFFFF); // 12%
  static const _badge = Color(0x33FFFFFF); // 20%

  static const _dots = '••••••';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(balanceSummaryProvider).value;
    final hidden = summary?.hidden ?? false;
    final rate = ref.watch(usdRateProvider);
    final cents = ref.watch(dollarStatsProvider).value?.cents ?? 0;
    final dollarsInSom = rate == null
        ? null
        : (cents * rate.value / 100).round();
    final names = [
      for (final m in summary?.methods ?? const []) m.method.name,
    ].take(_maxNames).join(' · ');

    // A filled indigo card, so the balance stands out from the others.
    return Container(
      // Less on top: the 44 px eye button already adds room there.
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      decoration: BoxDecoration(
        color: context.colors.hero,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        boxShadow: AppShadows.hero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'So’m balance',
                  style: AppText.label14.copyWith(color: _soft),
                ),
              ),
              Transform.translate(
                offset: const Offset(10, 0),
                child: CircleIconButton(
                  icon: hidden ? AppIcons.eyeOff : AppIcons.eye,
                  iconSize: 18,
                  color: _soft,
                  semanticLabel: hidden ? 'Show balance' : 'Hide balance',
                  onTap: () => ref
                      .read(settingsRepositoryProvider)
                      .setBalanceHidden(!hidden),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          AmountText(
            summary?.total ?? 0,
            hidden: hidden,
            color: Colors.white,
            style: AppText.amount40.copyWith(fontSize: 42),
            unitStyle: AppText.body17.copyWith(color: _unit, fontSize: 18),
            unitGap: 8,
          ),
          if (names.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              names,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption13Regular.copyWith(color: _unit),
            ),
          ],
          const SizedBox(height: 16),
          _DollarRow(
            cents: cents,
            inSom: dollarsInSom,
            hidden: hidden,
            onTap: () => context.push(Routes.dollars),
          ),
          if (cents != 0 && dollarsInSom != null && summary != null) ...[
            const SizedBox(height: 16),
            Text(
              'All together ≈ '
              '${hidden ? _dots : MoneyFormat.withCurrency(summary.total + dollarsInSom)}',
              style: AppText.small12Regular.copyWith(color: _unit),
            ),
          ],
          const SizedBox(height: 18),
          _RateRow(
            rate: rate,
            onConvert: () => context.push(Routes.buyDollars),
          ),
        ],
      ),
    );
  }
}

/// "$500.00 ≈ 6 325 000 UZS" on a lighter strip.
class _DollarRow extends StatelessWidget {
  const _DollarRow({
    required this.cents,
    required this.inSom,
    required this.hidden,
    required this.onTap,
  });

  final int cents;
  final int? inSom;
  final bool hidden;

  /// Opens the Dollar balance page.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dollars = hidden
        ? '\$${BalanceCard._dots}'
        : MoneyFormat.dollars(cents);
    final som = inSom;
    final radius = BorderRadius.circular(14);
    return Semantics(
      container: true,
      button: true,
      label: hidden ? 'Dollar balance hidden' : 'Dollar balance $dollars',
      excludeSemantics: true,
      child: Material(
        color: BalanceCard._row,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: BalanceCard._badge,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    r'$',
                    style: AppText.caption13Strong.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // The dollars take the width they need; the so'm text gets
                // the rest and is cut first.
                Text(
                  dollars,
                  maxLines: 1,
                  style: AppText.body16Strong.copyWith(color: Colors.white),
                ),
                if (som != null && cents != 0) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '≈ ${hidden ? BalanceCard._dots : MoneyFormat.withCurrency(som)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.small12Regular.copyWith(
                        color: BalanceCard._unit,
                      ),
                    ),
                  ),
                ] else
                  const Spacer(),
                const AppIcon(
                  AppIcons.chevronRight,
                  size: 18,
                  color: BalanceCard._unit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "1 USD = 12 650 UZS · CBU rate · today 09:00" with a "Convert" button.
class _RateRow extends ConsumerWidget {
  const _RateRow({required this.rate, required this.onConvert});

  final UsdRate? rate;
  final VoidCallback onConvert;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final now = ref.watch(clockProvider).now();
    final rate = this.rate;
    final updated = rate?.updatedAt;
    final subtitle = switch (rate) {
      null => 'No rate yet',
      UsdRate(manual: true) => 'Your rate',
      _ when updated != null =>
        'CBU rate · ${DateText.relativeDayTime(updated, now: now).toLowerCase()}',
      _ => 'CBU rate',
    };
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rate == null
                    ? '1 USD = — UZS'
                    : '1 USD = ${MoneyFormat.rate(rate.value)} UZS',
                style: AppText.caption13Strong.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppText.tiny11Regular.copyWith(
                  color: BalanceCard._faint,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Semantics(
          container: true,
          button: true,
          label: 'Convert so’m and dollars',
          excludeSemantics: true,
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onConvert,
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 40,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppIcon(AppIcons.exchange, size: 16, color: c.hero),
                      const SizedBox(width: 6),
                      Text(
                        'Convert',
                        style: AppText.label14Strong.copyWith(color: c.hero),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
