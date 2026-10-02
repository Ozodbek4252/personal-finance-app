import 'package:flutter/material.dart';

import '../../format/money_format.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';

/// One bar in [MonthBarChart].
class MonthBar {
  const MonthBar({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  /// Month name under the bar, like "Sep".
  final String label;

  /// Whole UZS. Shown above the bar in short form ("3.5M").
  final int value;

  /// The current month: colored bar and bold labels.
  final bool highlighted;
}

/// Simple vertical bars with a value above and a label below each bar.
/// Used for "Spending trend" (Dashboard) and the category trend
/// (Statistics).
class MonthBarChart extends StatelessWidget {
  const MonthBarChart({
    super.key,
    required this.bars,
    required this.highlightColor,
    this.maxBarHeight = 87,
    this.semanticLabel,
  });

  final List<MonthBar> bars;
  final Color highlightColor;
  final double maxBarHeight;
  final String? semanticLabel;

  static const _barWidth = 30.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final maxValue = bars.fold(0, (m, b) => b.value > m ? b.value : m);

    return Semantics(
      label:
          semanticLabel ??
          bars
              .map((b) => '${b.label} ${MoneyFormat.compact(b.value)}')
              .join(', '),
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final bar in bars)
            SizedBox(
              width: _barWidth + 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    bar.value == 0 ? '' : MoneyFormat.compact(bar.value),
                    style:
                        (bar.highlighted
                                ? AppText.tiny11Strong
                                : AppText.tiny11)
                            .copyWith(
                              color: bar.highlighted
                                  ? c.textPrimary
                                  : c.textTertiary,
                            ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    width: _barWidth,
                    // Empty months keep a thin line, so the month is visible.
                    height: maxValue == 0
                        ? 4
                        : (bar.value / maxValue * maxBarHeight).clamp(
                            4,
                            maxBarHeight,
                          ),
                    decoration: BoxDecoration(
                      color: bar.highlighted ? highlightColor : c.border,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bar.label,
                    style:
                        (bar.highlighted
                                ? AppText.small12Strong
                                : AppText.small12)
                            .copyWith(
                              color: bar.highlighted
                                  ? c.textPrimary
                                  : c.textTertiary,
                            ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
