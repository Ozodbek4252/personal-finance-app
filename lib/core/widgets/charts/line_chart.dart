import 'package:flutter/material.dart';

import '../../format/money_format.dart';
import '../../theme/app_colors.dart';
import 'chart_helpers.dart';

/// One point in [LineChart].
class LinePoint {
  const LinePoint({required this.label, required this.value});

  final String label;
  final int value;
}

/// Line with dots, a soft filled area under it, grid lines, and a
/// dashed line for the average. The last point is the selected period.
class LineChart extends StatelessWidget {
  const LineChart({
    super.key,
    required this.points,
    required this.color,
    required this.ticks,
    this.average,
    this.height = 170,
    this.semanticLabel,
  });

  final List<LinePoint> points;
  final Color color;

  /// Grid line values, lowest first. The chart spans from the first to
  /// the last tick.
  final List<double> ticks;
  final int? average;
  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: semanticLabel,
      image: true,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _LinePainter(
            points: points,
            color: color,
            ticks: ticks,
            average: average,
            grid: c.divider,
            label: c.textTertiary,
            strongLabel: c.textPrimary,
            dotFill: c.surface,
          ),
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.points,
    required this.color,
    required this.ticks,
    required this.average,
    required this.grid,
    required this.label,
    required this.strongLabel,
    required this.dotFill,
  });

  final List<LinePoint> points;
  final Color color;
  final List<double> ticks;
  final int? average;
  final Color grid;
  final Color label;
  final Color strongLabel;
  final Color dotFill;

  static const _left = 30.0;
  static const _inset = 6.0;
  static const _top = 14.0;

  /// Distance from the bottom to the lowest grid line.
  static const _lowLine = 49.0;

  /// Distance from the bottom to where the filled area ends.
  static const _fillEnd = 22.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || ticks.length < 2) return;
    final low = ticks.first;
    final high = ticks.last;
    final lowY = size.height - _lowLine;
    final fillBottom = size.height - _fillEnd;
    double y(double v) => lowY - (v - low) / (high - low) * (lowY - _top);

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final t in ticks) {
      canvas.drawLine(Offset(_left, y(t)), Offset(size.width, y(t)), gridPaint);
      paintLabel(
        canvas,
        MoneyFormat.compact(t.round()),
        Offset(0, y(t)),
        axisStyle(label),
        center: false,
      );
    }

    if (average case final avg?) {
      paintDashedLine(
        canvas,
        Offset(_left, y(avg.toDouble())),
        size.width,
        Paint()
          ..color = label
          ..strokeWidth = 1,
      );
    }

    final step = points.length <= 1
        ? 0.0
        : (size.width - _left - 2 * _inset) / (points.length - 1);
    final offsets = [
      for (final (i, p) in points.indexed)
        Offset(_left + _inset + i * step, y(p.value.toDouble())),
    ];

    final line = Path()..addPolygon(offsets, false);
    // Down from the first point, along the line, and back down.
    final area = Path()..moveTo(offsets.first.dx, fillBottom);
    for (final o in offsets) {
      area.lineTo(o.dx, o.dy);
    }
    area
      ..lineTo(offsets.last.dx, fillBottom)
      ..close();
    canvas.drawPath(area, Paint()..color = color.withValues(alpha: 0.08));
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round,
    );

    for (final (i, o) in offsets.indexed) {
      final last = i == offsets.length - 1;
      canvas.drawCircle(o, last ? 5 : 3.5, Paint()..color = dotFill);
      canvas.drawCircle(
        o,
        last ? 5 : 3.5,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      paintLabel(
        canvas,
        points[i].label,
        Offset(o.dx, size.height - 8),
        xLabelStyle(last ? strongLabel : label, strong: last),
      );
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => true;
}
