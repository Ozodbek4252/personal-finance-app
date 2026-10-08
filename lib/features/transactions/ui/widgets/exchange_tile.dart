import 'package:flutter/material.dart';

import '../../../../core/format/money_format.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/highlighted_text.dart';
import '../../../../data/models/currency.dart';
import '../../../../data/models/exchange_details.dart';

/// One exchange row: "Exchange · UZS → USD · 11:30" on the left; what
/// came in ("+$100.00") and what went out ("−1 265 000 UZS") on the
/// right.
class ExchangeTile extends StatelessWidget {
  const ExchangeTile({
    super.key,
    required this.item,
    required this.timeText,
    this.onTap,
    this.showDivider = false,
    this.highlight = '',
  });

  final ExchangeDetails item;
  final String timeText;
  final VoidCallback? onTap;
  final bool showDivider;
  final String highlight;

  /// "+$100.00" or "+506 000 UZS". With [signed] off there is no "+".
  static String gotText(ExchangeDetails e, {bool signed = true}) {
    final text = amountText(e.toCurrency, e.exchange.toAmount);
    return signed ? '+$text' : text;
  }

  /// "−1 265 000 UZS" or "−$40.00", fee included.
  static String gaveText(ExchangeDetails e) =>
      '${MoneyFormat.minus}'
      '${amountText(e.fromCurrency, e.exchange.fromAmount + e.exchange.fee)}';

  /// "$100.00" or "1 265 000 UZS".
  static String amountText(Currency currency, int minor) => switch (currency) {
    Currency.uzs => MoneyFormat.withCurrency(minor),
    Currency.usd => MoneyFormat.dollars(minor),
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final note = item.exchange.note;
    final route = '${item.fromCurrency.code} → ${item.toCurrency.code}';

    return Semantics(
      container: true,
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: showDivider
                ? Border(top: BorderSide(color: c.divider))
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AppIcon(AppIcons.exchange, size: 20, color: c.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Exchange', style: AppText.body15Strong),
                    const SizedBox(height: 2),
                    HighlightedText(
                      '${note ?? route} · $timeText',
                      query: note == null ? '' : highlight,
                      style: AppText.caption13Regular.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    gotText(item),
                    style: AppText.body15Strong.copyWith(
                      color: c.accent,
                      letterSpacing: -0.15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    gaveText(item),
                    style: AppText.small12Regular.copyWith(
                      color: c.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
