import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// A horizontal bar split into colored parts by size, like the
/// spending split on the Dashboard.
class StackedBar extends StatelessWidget {
  const StackedBar({
    super.key,
    required this.segments,
    this.height = 12,
    this.semanticLabel,
  });

  /// (value, color). Values must be positive.
  final List<(int, Color)> segments;
  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: SizedBox(
          height: height,
          child: Row(
            // Empty boxes take the smallest size they can, so stretch
            // them to the full bar height.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, (value, color)) in segments.indexed) ...[
                if (i > 0) const SizedBox(width: 2),
                Expanded(
                  // Flex needs an int; scale so small parts still show.
                  flex: (value / 1000).ceil().clamp(1, 1 << 30),
                  child: ColoredBox(color: color),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
