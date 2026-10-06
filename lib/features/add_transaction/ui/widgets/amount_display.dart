import 'package:flutter/material.dart';

import '../../../../core/format/money_format.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../data/models/transaction_kind.dart';

/// "Amount" label, the big number with a blinking cursor, and the
/// currency button.
class AmountDisplay extends StatelessWidget {
  const AmountDisplay({
    super.key,
    required this.amount,
    required this.kind,
    required this.onCurrencyTap,
  });

  final int amount;
  final TransactionKind kind;
  final VoidCallback onCurrencyTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isIncome = kind == TransactionKind.income;
    final String text;
    final Color color;
    if (amount == 0) {
      text = '0';
      color = c.textTertiary;
    } else {
      text = isIncome ? MoneyFormat.signed(amount) : MoneyFormat.amount(amount);
      color = isIncome ? c.income : c.textPrimary;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 2),
      child: Column(
        children: [
          Text(
            'Amount',
            style: AppText.caption13.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: 10),
          Semantics(
            liveRegion: true,
            label: 'Amount ${MoneyFormat.withCurrency(amount)}',
            excludeSemantics: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: FittedBox(
                    // Very long amounts shrink instead of overflowing.
                    fit: BoxFit.scaleDown,
                    child: Text(
                      text,
                      maxLines: 1,
                      style: AppText.amount48.copyWith(color: color),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const _Cursor(),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Semantics(
            container: true,
            button: true,
            label: 'Currency: ${MoneyFormat.currency}',
            excludeSemantics: true,
            child: Material(
              color: c.surface,
              shape: StadiumBorder(side: BorderSide(color: c.divider)),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onCurrencyTap,
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        MoneyFormat.currency,
                        style: AppText.caption13Strong.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      AppIcon(
                        AppIcons.chevronDown,
                        size: 14,
                        color: c.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Thin blue line that blinks, like a text cursor.
class _Cursor extends StatefulWidget {
  const _Cursor();

  @override
  State<_Cursor> createState() => _CursorState();
}

class _CursorState extends State<_Cursor> with SingleTickerProviderStateMixin {
  late final _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // No blinking when the user asked for less motion (and in tests).
    if (MediaQuery.disableAnimationsOf(context)) {
      _blink.stop();
      _blink.value = 1;
    } else if (!_blink.isAnimating) {
      _blink.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _blink, curve: Curves.easeInOutCubic),
      child: Container(
        width: 2,
        height: 42,
        decoration: BoxDecoration(
          color: context.colors.accent,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
