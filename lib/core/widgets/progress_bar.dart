import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Rounded progress bar, like "Saved this month" (80%).
///
/// [marker] draws a thin line at a second value, like last month's
/// savings rate on the Statistics screen.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    this.color,
    this.height = 8,
    this.marker,
  });

  /// From 0.0 to 1.0. Values outside are clamped.
  final double value;
  final Color? color;
  final double height;

  /// From 0.0 to 1.0, or null for no marker.
  final double? marker;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(AppRadius.pill);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return SizedBox(
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.surfaceMuted,
                    borderRadius: radius,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: width * value.clamp(0.0, 1.0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color ?? c.savings,
                    borderRadius: radius,
                  ),
                ),
              ),
              if (marker != null)
                Positioned(
                  left: width * marker!.clamp(0.0, 1.0) - 1,
                  top: -4,
                  bottom: -4,
                  width: 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.textPrimary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
