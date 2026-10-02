import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format/date_format.dart';
import '../core/format/money_format.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../core/theme/app_tokens.dart';
import '../core/theme/theme_mode_provider.dart';
import '../core/widgets/segmented_tabs.dart';
import 'widget_gallery.dart';

enum _PreviewTab { tokens, icons, widgets }

/// Temporary page to review the design system: tokens (Task 1),
/// icons and shared widgets (Task 2).
class DesignPreviewPage extends ConsumerStatefulWidget {
  const DesignPreviewPage({super.key});

  @override
  ConsumerState<DesignPreviewPage> createState() => _DesignPreviewPageState();
}

class _DesignPreviewPageState extends ConsumerState<DesignPreviewPage> {
  var _tab = _PreviewTab.tokens;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
          children: [
            Row(
              children: [
                Expanded(child: Text('Design preview', style: AppText.title22)),
                Switch(
                  value: isDark,
                  onChanged: (dark) => ref
                      .read(themeModeProvider.notifier)
                      .set(dark ? ThemeMode.dark : ThemeMode.light),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedTabs(
              options: const [
                SegmentOption(_PreviewTab.tokens, 'Tokens'),
                SegmentOption(_PreviewTab.icons, 'Icons'),
                SegmentOption(_PreviewTab.widgets, 'Widgets'),
              ],
              selected: _tab,
              onChanged: (tab) => setState(() => _tab = tab),
            ),
            const SizedBox(height: 16),
            ...switch (_tab) {
              _PreviewTab.tokens => _tokens(context),
              _PreviewTab.icons => const [IconGallery()],
              _PreviewTab.widgets => const [WidgetGallery()],
            },
          ],
        ),
      ),
    );
  }

  List<Widget> _tokens(BuildContext context) {
    final c = context.colors;
    final brightness = Theme.of(context).brightness;
    return [
      const _BalanceCardSample(),
      const SizedBox(height: 24),
      const _Label('Colors'),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _Swatch('background', c.background),
          _Swatch('surface', c.surface),
          _Swatch('surfaceMuted', c.surfaceMuted),
          _Swatch('textPrimary', c.textPrimary),
          _Swatch('textSecondary', c.textSecondary),
          _Swatch('textTertiary', c.textTertiary),
          _Swatch('divider', c.divider),
          _Swatch('border', c.border),
          _Swatch('primary', c.primary),
          _Swatch('income', c.income),
          _Swatch('incomeSoft', c.incomeSoft),
          _Swatch('expense', c.expense),
          _Swatch('expenseSoft', c.expenseSoft),
          _Swatch('savings', c.savings),
          _Swatch('savingsSoft', c.savingsSoft),
          _Swatch('highlight', c.highlight),
        ],
      ),
      const SizedBox(height: 24),
      const _Label('Category colors'),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final cc in CategoryColor.values)
            Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cc
                        .resolve(brightness)
                        .withValues(alpha: CategoryColor.tileAlpha(brightness)),
                    borderRadius: BorderRadius.circular(AppRadius.tile),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: cc.resolve(brightness),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  cc.name,
                  style: AppText.tiny11.copyWith(color: c.textTertiary),
                ),
              ],
            ),
        ],
      ),
      const SizedBox(height: 24),
      const _Label('Text styles'),
      ..._textStyles.entries.map(
        (e) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text('${e.key} · 12 450 000', style: e.value),
        ),
      ),
      const SizedBox(height: 24),
      const _Label('Formatters'),
      ..._formatterSamples().map(
        (s) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(s, style: AppText.body15),
        ),
      ),
    ];
  }

  static final _textStyles = {
    'amount40': AppText.amount40,
    'title22': AppText.title22,
    'title21': AppText.title21,
    'heading17': AppText.heading17,
    'body15Strong': AppText.body15Strong,
    'body15': AppText.body15,
    'label14': AppText.label14,
    'caption13': AppText.caption13,
    'small12': AppText.small12,
    'tiny11': AppText.tiny11,
  };

  static List<String> _formatterSamples() {
    final now = DateTime(2026, 9, 30, 15);
    return [
      MoneyFormat.amount(12450000),
      MoneyFormat.signed(-420000),
      MoneyFormat.signed(15000000),
      MoneyFormat.withCurrency(820000),
      '${MoneyFormat.compact(14500000, showSign: true)}  '
          '${MoneyFormat.compact(-3000000)}',
      '${PercentFormat.value(80.3)}  ${PercentFormat.change(-28.7)}  '
          '${PercentFormat.points(8.9)}',
      DateText.weekdayDayMonth(now),
      DateText.detail(DateTime(2026, 9, 30, 13, 40)),
      DateText.dayGroup(DateTime(2026, 9, 29), now: now),
      DateText.dayGroup(DateTime(2026, 9, 27), now: now),
      DateText.range(DateTime(2026, 9, 1), DateTime(2026, 9, 30)),
    ];
  }
}

/// Copy of the "Current balance" card from the Dashboard board,
/// built only from tokens, to compare with the design.
class _BalanceCardSample extends StatelessWidget {
  const _BalanceCardSample();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final brightness = Theme.of(context).brightness;

    Widget chip(String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text,
        style: AppText.small12.copyWith(color: c.textSecondary),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        boxShadow: AppShadows.card(brightness),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current balance',
            style: AppText.label14.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(MoneyFormat.amount(12450000), style: AppText.amount40),
              const SizedBox(width: 8),
              Text(
                MoneyFormat.currency,
                style: AppText.body17.copyWith(color: c.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              chip('Humo ${MoneyFormat.amount(6400000)}'),
              chip('Uzcard ${MoneyFormat.amount(4200000)}'),
              chip('Cash ${MoneyFormat.amount(1850000)}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: AppText.overline12.copyWith(color: context.colors.textTertiary),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.name, this.color);

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: 82,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.tile),
              border: Border.all(color: c.divider),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: AppText.tiny11.copyWith(color: c.textTertiary),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
