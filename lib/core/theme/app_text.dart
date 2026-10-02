import 'package:flutter/widgets.dart';

/// Text styles from the design. Font: Onest (variable font).
///
/// Names follow "size + weight". Styles have no color, so the
/// widget's default text color is used unless you set one.
abstract final class AppText {
  static const fontFamily = 'Onest';

  // Big amounts.
  static final amount48 = _style(48, FontWeight.w600, -0.03, height: 1);
  static final amount40 = _style(40, FontWeight.w600, -0.03, height: 1);

  // Titles and numbers inside cards.
  static final title28 = _style(28, FontWeight.w600, -0.02);
  static final title26 = _style(26, FontWeight.w600, -0.02);
  static final title22 = _style(22, FontWeight.w600, -0.02);
  static final title21 = _style(21, FontWeight.w600, -0.02);
  static final title20 = _style(20, FontWeight.w600, -0.02);

  /// Digits on the number keypad.
  static final keypad22 = _style(22, FontWeight.w500, 0);

  /// Section headers like "Where your money went".
  static final heading17 = _style(17, FontWeight.w600, -0.01);
  static final body17 = _style(17, FontWeight.w500, 0);
  static final body16Strong = _style(16, FontWeight.w600, 0);

  // Most list text.
  static final body15Strong = _style(15, FontWeight.w600, 0);
  static final body15 = _style(15, FontWeight.w500, 0);
  static final body15Regular = _style(15, FontWeight.w400, 0);

  static final label14Strong = _style(14, FontWeight.w600, 0);
  static final label14 = _style(14, FontWeight.w500, 0);

  static final caption13Strong = _style(13, FontWeight.w600, 0);
  static final caption13 = _style(13, FontWeight.w500, 0);
  static final caption13Regular = _style(13, FontWeight.w400, 0);

  /// Small upper-case group labels like "GENERAL".
  static final overline13 = _style(13, FontWeight.w600, 0.04);
  static final overline12 = _style(12, FontWeight.w600, 0.06);

  static final small12Strong = _style(12, FontWeight.w600, 0);
  static final small12 = _style(12, FontWeight.w500, 0);

  /// Bottom nav labels.
  static final tiny11Strong = _style(11, FontWeight.w600, 0);
  static final tiny11 = _style(11, FontWeight.w500, 0);

  /// [letterSpacingEm] is in "em", like the CSS in the design.
  static TextStyle _style(
    double size,
    FontWeight weight,
    double letterSpacingEm, {
    double height = 1.3,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      // A variable font needs the weight axis set as well.
      fontVariations: [FontVariation.weight(weight.value.toDouble())],
      // All numbers line up in columns ("tabular-nums" in the design).
      fontFeatures: const [FontFeature.tabularFigures()],
      letterSpacing: size * letterSpacingEm,
      height: height,
    );
  }
}
