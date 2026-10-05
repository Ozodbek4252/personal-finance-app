import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Ring chart with a small gap between parts, starting at the top.
/// [center] is drawn in the middle (for example "Total spent").
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.segments,
    this.size = 188,
    this.thickness = 22,
    this.center,
    this.semanticLabel,
  });

  /// (value, color). Values must be positive.
  final List<(int, Color)> segments;
  final double size;
  final double thickness;
  final Widget? center;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _DonutPainter(
            segments: segments,
            thickness: thickness,
            track: context.colors.surfaceMuted,
          ),
          child: center == null ? null : Center(child: center),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.segments,
    required this.thickness,
    required this.track,
  });

  final List<(int, Color)> segments;
  final double thickness;
  final Color track;

  /// Gap between parts, in pixels along the ring.
  static const _gap = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (size.shortestSide - thickness) / 2;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: radius,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;

    canvas.drawCircle(rect.center, radius, paint..color = track);

    final total = segments.fold(0, (s, e) => s + e.$1);
    if (total == 0) return;
    final gapAngle = segments.length > 1 ? _gap / radius : 0.0;
    var start = -math.pi / 2;
    for (final (value, color) in segments) {
      final sweep = value / total * 2 * math.pi;
      final drawn = math.max(sweep - gapAngle, 0.001);
      canvas.drawArc(rect, start, drawn, false, paint..color = color);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.segments != segments || old.track != track;
}
