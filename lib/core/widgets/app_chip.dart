import 'package:flutter/material.dart';

import '../icons/app_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_tokens.dart';
import 'app_icon.dart';

/// Tappable rounded chip, 40 px high.
///
/// Used for filters ("All", "Expenses") and for quick pickers on the
/// add screen ("Today", "Humo", "Add note").
/// A selected chip is filled with the primary color.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.onTap,
    this.selected = false,
    this.leadingIcon,
    this.trailingIcon,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final AppIconData? leadingIcon;

  /// Often [AppIcons.chevronDown] for chips that open a picker.
  final AppIconData? trailingIcon;

  /// What a screen reader says. Defaults to [label].
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final foreground = selected ? c.onPrimary : c.textPrimary;
    final shape = StadiumBorder(
      side: selected ? BorderSide.none : BorderSide(color: c.divider),
    );

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: Material(
        color: selected ? c.primary : c.surface,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leadingIcon != null) ...[
                  AppIcon(leadingIcon!, size: 16, color: foreground),
                  const SizedBox(width: 6),
                ],
                Text(label, style: AppText.label14.copyWith(color: foreground)),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 6),
                  AppIcon(
                    trailingIcon!,
                    size: 16,
                    color: selected ? foreground : c.textTertiary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A row of chips that scrolls sideways and lines up with the page edge.
class ChipRow extends StatelessWidget {
  const ChipRow({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.page),
  });

  final List<Widget> children;

  /// Use the page padding when the row is placed edge to edge.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            children[i],
          ],
        ],
      ),
    );
  }
}
