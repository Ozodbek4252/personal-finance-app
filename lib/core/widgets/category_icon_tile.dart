import 'package:flutter/material.dart';

import '../icons/app_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'app_icon.dart';

/// Rounded square with a category icon on a tinted background.
///
/// Default size (36) is used in lists. The add screen grid uses 34.
class CategoryIconTile extends StatelessWidget {
  const CategoryIconTile({
    super.key,
    required this.icon,
    required this.color,
    this.size = 36,
    this.iconSize = 18,
    this.radius = AppRadius.tile,
  });

  final AppIconData icon;
  final CategoryColor color;
  final double size;
  final double iconSize;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final tint = color.resolve(brightness);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: CategoryColor.tileAlpha(brightness)),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: AppIcon(icon, size: iconSize, color: tint),
    );
  }
}

/// Small round icon badge, like the green arrow next to "Income".
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    required this.foreground,
    required this.background,
    this.size = 28,
    this.iconSize = 16,
  });

  final AppIconData icon;
  final Color foreground;
  final Color background;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: AppIcon(icon, size: iconSize, color: foreground, strokeWidth: 2),
    );
  }
}
