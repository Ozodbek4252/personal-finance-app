import 'package:flutter/material.dart';

import '../../theme/app_text.dart';

/// Draws [text] so that its center (or left edge) sits at [at].
void paintLabel(
  Canvas canvas,
  String text,
  Offset at,
  TextStyle style, {
  bool center = true,
}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  final dx = center ? at.dx - tp.width / 2 : at.dx;
  tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
}

/// Style of axis numbers ("5M") in charts.
TextStyle axisStyle(Color color) => AppText.tiny11.copyWith(color: color);

/// Style of axis names ("Sep"); the current one is bold.
TextStyle xLabelStyle(Color color, {bool strong = false}) =>
    (strong ? AppText.small12Strong : AppText.small12).copyWith(color: color);

/// Draws a dashed horizontal line.
void paintDashedLine(
  Canvas canvas,
  Offset from,
  double toX,
  Paint paint, {
  double dash = 4,
  double gap = 4,
}) {
  for (var x = from.dx; x < toX; x += dash + gap) {
    canvas.drawLine(
      Offset(x, from.dy),
      Offset((x + dash).clamp(x, toX), from.dy),
      paint,
    );
  }
}
