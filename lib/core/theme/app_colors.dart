import 'package:flutter/material.dart';

/// Color tokens from the "Personal Finance App" design.
///
/// Read them in widgets with `context.colors` (see [AppColorsX]).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.divider,
    required this.border,
    required this.primary,
    required this.onPrimary,
    required this.income,
    required this.incomeSoft,
    required this.expense,
    required this.expenseSoft,
    required this.savings,
    required this.savingsSoft,
    required this.highlight,
  });

  /// Page background.
  final Color background;

  /// Cards, nav bar, sheets.
  final Color surface;

  /// Pills, progress track, inputs.
  final Color surfaceMuted;

  /// Main text and icons.
  final Color textPrimary;

  /// Labels and secondary text.
  final Color textSecondary;

  /// Hints, units ("UZS") and inactive icons.
  final Color textTertiary;

  /// Thin lines between rows.
  final Color divider;

  /// Outlines of inputs and outlined buttons.
  final Color border;

  /// Main buttons and the center add button.
  final Color primary;
  final Color onPrimary;

  final Color income;
  final Color incomeSoft;
  final Color expense;
  final Color expenseSoft;
  final Color savings;
  final Color savingsSoft;

  /// Background of a search match inside text.
  final Color highlight;

  static const light = AppColors(
    background: Color(0xFFF5F4F0),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFEEEDE8),
    textPrimary: Color(0xFF141416),
    textSecondary: Color(0xFF56554F),
    textTertiary: Color(0xFF6E6C66),
    divider: Color(0xFFE4E2DB),
    border: Color(0xFFD9D7D0),
    primary: Color(0xFF141416),
    onPrimary: Color(0xFFFFFFFF),
    income: Color(0xFF17784F),
    incomeSoft: Color(0xFFE2F1E9),
    expense: Color(0xFFC0432A),
    expenseSoft: Color(0xFFF9E7E2),
    savings: Color(0xFF2A55BE),
    savingsSoft: Color(0xFFE5EBF8),
    highlight: Color(0xFFFBEFD8),
  );

  static const dark = AppColors(
    background: Color(0xFF0E0E10),
    surface: Color(0xFF18181B),
    surfaceMuted: Color(0xFF232327),
    textPrimary: Color(0xFFF3F2EF),
    textSecondary: Color(0xFFAAA8A2),
    textTertiary: Color(0xFF98968F),
    divider: Color(0xFF2A2A2F),
    border: Color(0xFF34343A),
    primary: Color(0xFFF3F2EF),
    onPrimary: Color(0xFF0E0E10),
    income: Color(0xFF4FC28B),
    incomeSoft: Color(0x244FC28B), // 14%
    expense: Color(0xFFF08A70),
    expenseSoft: Color(0x24F08A70), // 14%
    savings: Color(0xFF8DA8F3),
    savingsSoft: Color(0x248DA8F3), // 14%
    // Not shown in the dark boards; a muted amber that keeps text readable.
    highlight: Color(0x52E9B45E),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? divider,
    Color? border,
    Color? primary,
    Color? onPrimary,
    Color? income,
    Color? incomeSoft,
    Color? expense,
    Color? expenseSoft,
    Color? savings,
    Color? savingsSoft,
    Color? highlight,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      divider: divider ?? this.divider,
      border: border ?? this.border,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      income: income ?? this.income,
      incomeSoft: incomeSoft ?? this.incomeSoft,
      expense: expense ?? this.expense,
      expenseSoft: expenseSoft ?? this.expenseSoft,
      savings: savings ?? this.savings,
      savingsSoft: savingsSoft ?? this.savingsSoft,
      highlight: highlight ?? this.highlight,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceMuted: l(surfaceMuted, other.surfaceMuted),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textTertiary: l(textTertiary, other.textTertiary),
      divider: l(divider, other.divider),
      border: l(border, other.border),
      primary: l(primary, other.primary),
      onPrimary: l(onPrimary, other.onPrimary),
      income: l(income, other.income),
      incomeSoft: l(incomeSoft, other.incomeSoft),
      expense: l(expense, other.expense),
      expenseSoft: l(expenseSoft, other.expenseSoft),
      savings: l(savings, other.savings),
      savingsSoft: l(savingsSoft, other.savingsSoft),
      highlight: l(highlight, other.highlight),
    );
  }
}

/// Colors a user can pick for a category.
///
/// Each one has a light and a dark version. The icon tile behind a
/// category icon uses the same color with low opacity ([tileAlpha]).
enum CategoryColor {
  blue(Color(0xFF3563C9), Color(0xFF7FA2F0)),
  green(Color(0xFF2A7F55), Color(0xFF6FCB9C)),
  orange(Color(0xFFB75A17), Color(0xFFF0A36A)),
  purple(Color(0xFF7450BF), Color(0xFFB39AF0)),
  teal(Color(0xFF1D737A), Color(0xFF6CC7CE)),
  // Brown, pink and gray have no dark board in the design.
  // Their dark values follow the same "lighter, softer" rule.
  brown(Color(0xFF7E6136), Color(0xFFCDB089)),
  pink(Color(0xFFAB437A), Color(0xFFE891BE)),
  red(Color(0xFFB8413A), Color(0xFFF0918A)),
  gray(Color(0xFF66655F), Color(0xFFB5B3AC)),
  amber(Color(0xFF9C6512), Color(0xFFE9B45E)),
  indigo(Color(0xFF4655B8), Color(0xFF9AA5F0)),
  // Same green as the income color. Used by "Salary".
  emerald(Color(0xFF17784F), Color(0xFF4FC28B));

  const CategoryColor(this.light, this.dark);

  final Color light;
  final Color dark;

  /// The 9 colors shown in the "Create category" color picker.
  static const pickable = [
    blue, green, orange, purple, teal, brown, pink, red, gray, //
  ];

  /// Finds a color by its stored name. Unknown names give [gray].
  static CategoryColor fromKey(String key) =>
      values.firstWhere((c) => c.name == key, orElse: () => gray);

  Color resolve(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  /// Opacity of the icon tile background.
  static double tileAlpha(Brightness brightness) =>
      brightness == Brightness.dark ? 0.16 : 0.12;
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
