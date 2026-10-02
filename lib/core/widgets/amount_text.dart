import 'package:flutter/material.dart';

import '../format/money_format.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// A money amount with the "UZS" unit after it, on the same baseline.
///
/// Examples from the design:
/// - Balance: big "12 450 000" with "UZS" at 17 px.
/// - List row: "−420 000" with a small "UZS" at 11 px.
class AmountText extends StatelessWidget {
  const AmountText(
    this.amount, {
    super.key,
    this.style,
    this.unitStyle,
    this.color,
    this.signed = false,
    this.showUnit = true,
    this.unitGap = 4,
    this.hidden = false,
  });

  /// Whole UZS.
  final int amount;

  /// Style of the number. Defaults to [AppText.body15Strong].
  final TextStyle? style;

  /// Style of "UZS". Defaults to 11 px in the tertiary text color.
  final TextStyle? unitStyle;

  /// Color of the number. Defaults to the primary text color.
  final Color? color;

  /// Show "+" for positive amounts (negative amounts always get "−").
  final bool signed;

  final bool showUnit;
  final double unitGap;

  /// Hide the number behind dots, for the "Hide balance" button.
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final String value;
    if (hidden) {
      value = '••••••';
    } else {
      value = signed ? MoneyFormat.signed(amount) : MoneyFormat.amount(amount);
    }

    final number = Text(
      value,
      maxLines: 1,
      softWrap: false,
      style: (style ?? AppText.body15Strong).copyWith(
        color: color ?? c.textPrimary,
      ),
    );
    if (!showUnit) return number;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(child: number),
        SizedBox(width: unitGap),
        Text(
          MoneyFormat.currency,
          style: (unitStyle ?? AppText.tiny11).copyWith(
            color: unitStyle?.color ?? c.textTertiary,
          ),
        ),
      ],
    );
  }
}
