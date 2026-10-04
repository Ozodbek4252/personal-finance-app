import 'package:flutter/material.dart';

import '../icons/app_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import 'app_icon.dart';

/// 44 px round icon button.
///
/// [CircleIconButton.raised] is the white circle with a shadow, like the
/// search button on the Dashboard. The plain one has no background and is
/// used for close and back buttons in headers.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.iconSize = 20,
    this.color,
  }) : _raised = false;

  const CircleIconButton.raised({
    super.key,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.iconSize = 20,
    this.color,
  }) : _raised = true;

  final AppIconData icon;
  final VoidCallback? onTap;
  final String semanticLabel;
  final double iconSize;
  final Color? color;
  final bool _raised;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final button = Material(
      color: _raised ? c.surface : Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox.square(
          dimension: AppSpacing.touch,
          child: Center(
            child: AppIcon(icon, size: iconSize, color: color),
          ),
        ),
      ),
    );

    return Semantics(
      container: true,
      button: true,
      label: semanticLabel,
      child: _raised
          ? DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: AppShadows.card(Theme.of(context).brightness),
              ),
              child: button,
            )
          : button,
    );
  }
}

/// Full-width dark button, 56 px high. Example: "Save expense".
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.background,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppIconData? icon;

  /// Fill color. Defaults to the primary color; "Save income" is green.
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onPressed != null;
    return _BaseButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
      height: 56,
      radius: AppRadius.button,
      background: enabled ? (background ?? c.primary) : c.surfaceMuted,
      foreground: enabled ? c.onPrimary : c.textTertiary,
      textStyle: AppText.body16Strong,
    );
  }
}

/// Outlined button, 52 px high. Examples: "Edit", "Duplicate".
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppIconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _BaseButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
      height: 52,
      radius: AppRadius.field,
      background: c.surface,
      foreground: c.textPrimary,
      border: BorderSide(color: c.divider),
      textStyle: AppText.body15Strong,
    );
  }
}

/// Text-only button, like "Delete transaction" in red.
class TextActionButton extends StatelessWidget {
  const TextActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppIconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return _BaseButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
      height: 48,
      radius: AppRadius.field,
      background: Colors.transparent,
      foreground: color ?? context.colors.textPrimary,
      textStyle: AppText.body15Strong,
    );
  }
}

class _BaseButton extends StatelessWidget {
  const _BaseButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.height,
    required this.radius,
    required this.background,
    required this.foreground,
    required this.textStyle,
    this.border = BorderSide.none,
  });

  final String label;
  final AppIconData? icon;
  final VoidCallback? onPressed;
  final double height;
  final double radius;
  final Color background;
  final Color foreground;
  final TextStyle textStyle;
  final BorderSide border;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: border,
    );
    return Semantics(
      container: true,
      button: true,
      enabled: onPressed != null,
      child: Material(
        color: background,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          customBorder: shape,
          child: SizedBox(
            height: height,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  AppIcon(icon!, size: 18, color: foreground),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle.copyWith(color: foreground),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
