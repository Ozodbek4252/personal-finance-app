import 'package:flutter/material.dart';

import '../../data/db/app_database.dart';
import '../../data/models/display_style.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'app_icon.dart';

/// Rounded category button with a small round icon. Selected chips
/// get a colored border and a tinted background.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final CategoryRow category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final brightness = Theme.of(context).brightness;
    final tint = category.color.resolve(brightness);
    final soft = tint.withValues(alpha: CategoryColor.tileAlpha(brightness));
    final shape = StadiumBorder(
      side: selected
          ? BorderSide(color: tint, width: 2)
          : BorderSide(color: c.divider),
    );
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: category.name,
      excludeSemantics: true,
      child: Material(
        color: selected ? soft : c.surface,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: Container(
            height: 40,
            padding: const EdgeInsets.only(left: 6, right: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: soft,
                    shape: BoxShape.circle,
                  ),
                  child: AppIcon(category.icon, size: 15, color: tint),
                ),
                const SizedBox(width: 6),
                Text(
                  category.name,
                  style: selected ? AppText.label14Strong : AppText.label14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
