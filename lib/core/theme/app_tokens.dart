import 'package:flutter/widgets.dart';

/// Corner radius values from the design.
abstract final class AppRadius {
  static const pill = 999.0;
  static const card = 20.0;
  static const cardLarge = 24.0;
  static const tile = 10.0;
  static const field = 14.0;
  static const button = 16.0;
  static const small = 12.0;
}

/// Spacing values used again and again in the design.
abstract final class AppSpacing {
  /// Left and right page padding.
  static const page = 16.0;

  /// Gap between cards on a page.
  static const section = 16.0;

  /// Padding inside a normal card.
  static const card = 16.0;

  /// Smallest touch target size.
  static const touch = 44.0;
}

/// Card shadows. Dark mode uses a thin light outline instead.
abstract final class AppShadows {
  static const cardLight = [
    BoxShadow(color: Color(0x0A141416), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color(0x0D141416), offset: Offset(0, 6), blurRadius: 20),
  ];

  static const cardDark = [
    BoxShadow(color: Color(0x08FFFFFF), spreadRadius: 1),
  ];

  /// Shadow under the round add button in the bottom nav.
  static const fab = [
    BoxShadow(color: Color(0x47141416), offset: Offset(0, 6), blurRadius: 18),
  ];

  static List<BoxShadow> card(Brightness brightness) =>
      brightness == Brightness.dark ? cardDark : cardLight;
}
