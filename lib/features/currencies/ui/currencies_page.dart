import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/date_format.dart';
import '../../../core/format/money_format.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/dashed_border.dart';
import '../../../core/widgets/segmented_tabs.dart';
import '../../../core/widgets/text_input_dialog.dart';
import '../../../data/providers/data_providers.dart';
import '../../../data/rates/rate_service.dart';
import '../../../data/rates/rate_source.dart';

/// Settings > Currencies: so'm is the main currency, the dollar is the
/// second one. Here the user picks where the USD rate comes from and
/// where dollar amounts are shown.
class CurrenciesPage extends ConsumerStatefulWidget {
  const CurrenciesPage({super.key});

  @override
  ConsumerState<CurrenciesPage> createState() => _CurrenciesPageState();
}

class _CurrenciesPageState extends ConsumerState<CurrenciesPage> {
  bool _refreshing = false;

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      await ref.read(rateServiceProvider).refresh();
    } on RateUnavailableException {
      if (mounted) {
        _toast('Could not get the rate. Check your internet connection.');
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _setManual(bool manual) async {
    final settings = ref.read(settingsRepositoryProvider);
    if (manual && ref.read(currentSettingsProvider).usdManualRate == null) {
      // Start from the CBU rate, so the user only adjusts it.
      final current = ref.read(usdRateProvider);
      if (current == null) {
        if (!await _editManualRate()) return;
      } else {
        await settings.setUsdManualRate(current.value);
      }
    }
    await settings.setUsdRateManual(manual);
  }

  /// Asks for a rate and saves it. Returns false when cancelled.
  Future<bool> _editManualRate() async {
    final current =
        ref.read(currentSettingsProvider).usdManualRate ??
        ref.read(usdRateProvider)?.value;
    final text = await showTextInputDialog(
      context,
      title: 'Your rate',
      initial: current == null ? '' : _plainRate(current),
      hint: '12650',
      suffix: 'UZS for 1 USD',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      validate: (t) =>
          _parseRate(t) == null ? 'Type a number, like 12650' : null,
    );
    final rate = text == null ? null : _parseRate(text);
    if (rate == null) return false;
    await ref.read(settingsRepositoryProvider).setUsdManualRate(rate);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final settings = ref.watch(currentSettingsProvider);
    final repo = ref.read(settingsRepositoryProvider);
    final rate = ref.watch(usdRateProvider);
    final manual = settings.usdRateManual;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => context.pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                children: [
                  const _GroupLabel('Your currencies'),
                  const AppCard(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        _CurrencyRow(
                          symbol: 'S',
                          code: 'UZS',
                          name: 'so’m',
                          subtitle: 'Totals and statistics are counted in so’m',
                          badge: 'Main',
                        ),
                        _CurrencyRow(
                          symbol: r'$',
                          code: 'USD',
                          name: 'dollar',
                          subtitle: 'Shown next to so’m amounts',
                          badge: 'Second',
                          showDivider: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _GroupLabel('Exchange rate'),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SegmentedTabs(
                          options: const [
                            SegmentOption(false, 'Auto (CBU)'),
                            SegmentOption(true, 'Manual'),
                          ],
                          selected: manual,
                          onChanged: _setManual,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _RateText(rate: rate, manual: manual),
                            ),
                            const SizedBox(width: 12),
                            _OutlinedSmall(
                              label: manual
                                  ? 'Edit'
                                  : _refreshing
                                  ? 'Updating…'
                                  : 'Refresh',
                              onTap: manual
                                  ? _editManualRate
                                  : _refreshing
                                  ? null
                                  : _refresh,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          manual
                              ? 'This rate is used for new exchanges and '
                                    '≈ \$ amounts until you switch back to '
                                    'Auto. Old exchanges keep their own rate.'
                              : 'Without internet, the last saved rate is '
                                    'used. Each exchange keeps its own rate, '
                                    'so old records never change.',
                          style: AppText.small12Regular.copyWith(
                            color: c.textTertiary,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _GroupLabel('Display'),
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        _SwitchRow(
                          label: 'Show USD on home',
                          subtitle: 'Balance, income and expenses show ≈ \$',
                          value: settings.showUsdOnHome,
                          onChanged: repo.setShowUsdOnHome,
                        ),
                        _SwitchRow(
                          label: 'Show USD in transaction list',
                          subtitle: 'Adds ≈ \$ under each amount',
                          value: settings.showUsdInList,
                          onChanged: repo.setShowUsdInList,
                          showDivider: true,
                        ),
                        _SwitchRow(
                          label: 'Round dollars',
                          subtitle:
                              '≈ \$${MoneyFormat.amount(1484)} instead of '
                              '\$${MoneyFormat.amount(1484)}.19',
                          value: settings.roundDollars,
                          onChanged: repo.setRoundDollars,
                          showDivider: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _AddCurrencyButton(
                    onTap: () =>
                        _toast('Only so’m and dollar are supported for now.'),
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

/// "12 650.5" or "12,650.5" → 12650.5. Null when it is not a rate.
double? _parseRate(String text) {
  var t = text.trim().replaceAll(' ', '');
  // A single comma is a decimal mark ("12650,37").
  if (!t.contains('.') && ','.allMatches(t).length == 1) {
    t = t.replaceAll(',', '.');
  } else {
    t = t.replaceAll(',', '');
  }
  final rate = double.tryParse(t);
  return rate != null && rate > 0 && rate.isFinite ? rate : null;
}

/// 12650.0 → "12650", 11778.45 → "11778.45". For the edit field.
String _plainRate(double rate) =>
    rate == rate.roundToDouble() ? '${rate.round()}' : rate.toStringAsFixed(2);

class _RateText extends ConsumerWidget {
  const _RateText({required this.rate, required this.manual});

  final UsdRate? rate;
  final bool manual;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final now = ref.watch(clockProvider).now();
    final updated = rate?.updatedAt;
    final subtitle = switch ((rate, manual)) {
      (null, _) => 'No rate yet. Connect to the internet or use Manual.',
      (_, true) => 'Your own rate',
      _ when updated != null =>
        'Updated ${DateText.relativeDayTime(updated, now: now).toLowerCase()}',
      _ => 'Saved CBU rate',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // One line: shrinks a little on narrow phones or big text.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            rate == null
                ? '1 USD = — UZS'
                : '1 USD = ${MoneyFormat.rate(rate!.value)} UZS',
            maxLines: 1,
            style: AppText.title20.copyWith(letterSpacing: 0),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: AppText.small12Regular.copyWith(color: c.textTertiary),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

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
                  'Currencies',
                  textAlign: TextAlign.center,
                  style: AppText.heading17,
                ),
              ),
            ),
            const SizedBox(width: 100),
          ],
        ),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: AppText.overline13.copyWith(color: context.colors.textSecondary),
      ),
    );
  }
}

/// Thin line above every row but the first.
class _Divided extends StatelessWidget {
  const _Divided({required this.show, required this.child});

  final bool show;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: show
            ? Border(top: BorderSide(color: context.colors.divider))
            : null,
      ),
      child: child,
    );
  }
}

class _CurrencyRow extends StatelessWidget {
  const _CurrencyRow({
    required this.symbol,
    required this.code,
    required this.name,
    required this.subtitle,
    required this.badge,
    this.showDivider = false,
  });

  final String symbol;
  final String code;
  final String name;
  final String subtitle;
  final String badge;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _Divided(
      show: showDivider,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.accentSoft,
                shape: BoxShape.circle,
              ),
              child: Text(
                symbol,
                style: AppText.label14Strong.copyWith(color: c.accent),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      text: code,
                      children: [
                        TextSpan(
                          text: ' · $name',
                          style: AppText.body15Regular.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    style: AppText.body15Strong,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppText.small12Regular.copyWith(
                      color: c.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: c.accentSoft,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: AppText.tiny11Strong.copyWith(color: c.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.showDivider = false,
  });

  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _Divided(
      show: showDivider,
      child: MergeSemantics(
        child: InkWell(
          onTap: () => onChanged(!value),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: AppText.body15),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: AppText.small12Regular.copyWith(
                            color: c.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Switch(
                    value: value,
                    activeTrackColor: c.primary,
                    activeThumbColor: Colors.white,
                    onChanged: onChanged,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// White button with a thin border, like "Refresh".
class _OutlinedSmall extends StatelessWidget {
  const _OutlinedSmall({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(color: c.divider),
    );
    return Semantics(
      container: true,
      button: true,
      enabled: onTap != null,
      child: Material(
        color: c.surface,
        shape: shape,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: SizedBox(
            height: 40,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: AppText.label14.copyWith(
                    color: onTap == null ? c.textTertiary : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddCurrencyButton extends StatelessWidget {
  const _AddCurrencyButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      child: DashedBorder(
        color: c.border,
        radius: 14,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcon(AppIcons.plus, size: 18, color: c.textPrimary),
                const SizedBox(width: 8),
                Text('Add currency', style: AppText.body15Strong),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
