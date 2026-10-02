import '../../core/icons/app_icons.dart';
import '../../core/theme/app_colors.dart';
import '../db/app_database.dart';

/// Turns the stored icon and color keys into real icons and colors.
extension CategoryStyle on CategoryRow {
  AppIconData get icon => iconFromKey(iconKey);
  CategoryColor get color => CategoryColor.fromKey(colorKey);
}

extension PaymentMethodStyle on PaymentMethodRow {
  AppIconData get icon => iconFromKey(iconKey);
}

/// Unknown keys fall back to the "box" icon.
AppIconData iconFromKey(String key) => AppIcons.all[key] ?? AppIcons.box;
