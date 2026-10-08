import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../domain/amount_input.dart';

/// 3 × 4 number pad with a "000" key and a delete key.
/// Holding the delete key clears the whole amount.
class NumberKeypad extends StatelessWidget {
  const NumberKeypad({
    super.key,
    required this.onKey,
    required this.onClear,
    this.decimal = false,
  });

  final ValueChanged<KeypadKey> onKey;
  final VoidCallback onClear;

  /// Show a "." key instead of "000", for amounts with cents.
  final bool decimal;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['000', '0', null], // null = delete key
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (r, row) in _rows.indexed) ...[
          if (r > 0) const SizedBox(height: 8),
          Row(
            children: [
              for (final (i, label) in row.indexed) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: label == '000' && decimal
                      ? _Key(
                          semanticLabel: 'Decimal point',
                          onTap: () => onKey(const DecimalKey()),
                          child: Text('.', style: AppText.keypad22),
                        )
                      : label == null
                      ? _Key(
                          semanticLabel: 'Delete digit',
                          onTap: () => onKey(const BackspaceKey()),
                          onLongPress: onClear,
                          child: AppIcon(AppIcons.backspace, size: 22),
                        )
                      : _Key(
                          semanticLabel: label,
                          onTap: () => onKey(DigitKey(label)),
                          child: Text(label, style: AppText.keypad22),
                        ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.child,
    required this.onTap,
    required this.semanticLabel,
    this.onLongPress,
  });

  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.field);
    return Semantics(
      container: true,
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: AppShadows.card(Theme.of(context).brightness),
        ),
        child: Material(
          color: context.colors.surface,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            onLongPress: onLongPress == null
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    onLongPress!();
                  },
            child: SizedBox(height: 48, child: Center(child: child)),
          ),
        ),
      ),
    );
  }
}
