import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';

/// Small rounded label that is not tappable.
///
/// Examples: "Humo 6 400 000" on the balance card,
/// "Default" on a payment method.
class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.background, this.foreground})
    : _badge = false;

  /// A stronger label with bigger, bold text, like "80% of income".
  const Pill.badge(this.text, {super.key, this.background, this.foreground})
    : _badge = true;

  final String text;
  final Color? background;
  final Color? foreground;
  final bool _badge;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: _badge ? 4 : 5),
      decoration: BoxDecoration(
        color: background ?? c.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text,
        style: (_badge ? AppText.caption13Strong : AppText.small12).copyWith(
          color: foreground ?? c.textSecondary,
        ),
      ),
    );
  }
}
