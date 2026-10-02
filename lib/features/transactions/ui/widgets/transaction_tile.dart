import 'package:flutter/material.dart';

import '../../../../core/format/date_format.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/amount_text.dart';
import '../../../../core/widgets/category_icon_tile.dart';
import '../../../../data/models/display_style.dart';
import '../../../../data/models/transaction_details.dart';
import '../../../../data/models/transaction_kind.dart';

/// One transaction row: category tile, name, note and time on the left;
/// amount and payment method on the right.
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.item,
    required this.timeText,
    this.onTap,
    this.showDivider = false,
  });

  final TransactionDetails item;

  /// "13:40" inside a day group, or "Yesterday, 18:04" in mixed lists.
  final String timeText;
  final VoidCallback? onTap;

  /// Thin line above the row, for every row except the first.
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final note = item.transaction.note;
    final isIncome = item.kind == TransactionKind.income;

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
              CategoryIconTile(
                icon: item.category.icon,
                color: item.category.color,
                size: 40,
                iconSize: 20,
                radius: 12,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body15Strong,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      note == null ? timeText : '$note · $timeText',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                  AmountText(
                    item.signedAmount,
                    signed: true,
                    color: isIncome ? c.income : c.textPrimary,
                    style: AppText.body15Strong.copyWith(letterSpacing: -0.15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.paymentMethod.name,
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

  /// Time text for lists that mix days, kept short so the note fits:
  /// "13:40" for today, else "Yesterday" or "27 Sep".
  static String mixedDayTime(TransactionDetails item, DateTime now) {
    final d = item.occurredAt;
    final today =
        d.year == now.year && d.month == now.month && d.day == now.day;
    return today ? DateText.time(d) : DateText.shortDay(d, now: now);
  }
}
