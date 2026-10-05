import 'package:flutter/material.dart';

import '../../format/money_format.dart';
import '../../theme/app_colors.dart';
import 'chart_helpers.dart';

/// One group of two bars (income and expenses) in [GroupedBarChart].
class BarGroup {
  const BarGroup({
    required this.label,
    required this.first,
    required this.second,
    this.highlighted = false,
  });

  final String label;
  final int first;
  final int second;

  /// The selected period: bold label.
  final bool highlighted;
}

/// Pairs of bars per period with horizontal grid lines, like
/// "Income vs expenses".
class GroupedBarChart extends StatelessWidget {
  const GroupedBarChart({
    super.key,
    required this.groups,
    required this.firstColor,
    required this.secondColor,
    required this.ticks,
    this.height = 200,
    this.semanticLabel,
  });

  final List<BarGroup> groups;
  final Color firstColor;
  final Color secondColor;

  /// Values for the grid lines, from 0 up.
  final List<double> ticks;
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
          painter: _GroupedBarPainter(
            groups: groups,
            firstColor: firstColor,
            secondColor: secondColor,
            ticks: ticks,
            grid: c.divider,
            label: c.textTertiary,
            strongLabel: c.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _GroupedBarPainter extends CustomPainter {
  _GroupedBarPainter({
    required this.groups,
    required this.firstColor,
    required this.secondColor,
    required this.ticks,
    required this.grid,
    required this.label,
    required this.strongLabel,
  });

  final List<BarGroup> groups;
  final Color firstColor;
  final Color secondColor;
  final List<double> ticks;
  final Color grid;
  final Color label;
  final Color strongLabel;

  static const _left = 30.0; // Room for the axis numbers.
  static const _top = 13.0;
  static const _bottomLabels = 22.0;
  static const _barWidth = 14.0;
  static const _barGap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final base = size.height - _bottomLabels;
    final maxValue = [
      ...groups.expand((g) => [g.first, g.second]).map((v) => v.toDouble()),
      ...ticks,
    ].fold(0.0, (m, v) => v > m ? v : m);
    if (maxValue == 0) return;
    double y(double v) => base - v / maxValue * (base - _top);

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

    final step = groups.length <= 1
        ? 0.0
        : (size.width - _left - 2 * _barWidth - _barGap) / (groups.length - 1);
    for (final (i, g) in groups.indexed) {
      final x = _left + i * step;
      for (final (j, (value, color)) in [
        (g.first, firstColor),
        (g.second, secondColor),
      ].indexed) {
        if (value <= 0) continue;
        final left = x + j * (_barWidth + _barGap);
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTRB(left, y(value.toDouble()), left + _barWidth, base),
            topLeft: const Radius.circular(4),
            topRight: const Radius.circular(4),
          ),
          Paint()..color = color,
        );
      }
      paintLabel(
        canvas,
        g.label,
        Offset(x + _barWidth + _barGap / 2, size.height - 8),
        xLabelStyle(g.highlighted ? strongLabel : label, strong: g.highlighted),
      );
    }
  }

  @override
  bool shouldRepaint(_GroupedBarPainter old) => true;
}
