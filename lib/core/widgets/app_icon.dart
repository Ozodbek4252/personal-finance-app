import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../icons/app_icons.dart';
import '../theme/app_colors.dart';

/// Draws an [AppIconData] line icon.
///
/// The color defaults to the primary text color.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    super.key,
    this.size = 20,
    this.color,
    this.strokeWidth = 1.8,
  });

  final AppIconData icon;
  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
      'fill="none" stroke="currentColor" stroke-width="$strokeWidth" '
      'stroke-linecap="round" stroke-linejoin="round">'
      '${icon.svgBody}</svg>',
      width: size,
      height: size,
      theme: SvgTheme(currentColor: color ?? context.colors.textPrimary),
      excludeFromSemantics: true,
    );
  }
}
