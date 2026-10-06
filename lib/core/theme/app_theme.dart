import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text.dart';

/// Builds the light and dark [ThemeData] from the design tokens.
abstract final class AppTheme {
  static ThemeData get light => _build(AppColors.light, Brightness.light);
  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      secondary: c.savings,
      onSecondary: c.onPrimary,
      error: c.expense,
      onError: c.onPrimary,
      surface: c.surface,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      outline: c.border,
      outlineVariant: c.divider,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: AppText.fontFamily,
      scaffoldBackgroundColor: c.background,
      dividerColor: c.divider,
      splashFactory: InkSparkle.splashFactory,
      extensions: [c],
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: c.textPrimary,
        displayColor: c.textPrimary,
      ),
      dividerTheme: DividerThemeData(color: c.divider, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppText.heading17.copyWith(color: c.textPrimary),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        // Dark on light (and light on dark), so it stands apart from the
        // indigo buttons.
        backgroundColor: c.textPrimary,
        contentTextStyle: AppText.label14.copyWith(color: c.background),
        actionTextColor: c.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        modalBackgroundColor: c.surface,
        showDragHandle: true,
        dragHandleColor: c.border,
        modalBarrierColor: const Color(0x7A15162B), // 48% ink
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}
