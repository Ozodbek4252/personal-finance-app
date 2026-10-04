import 'package:flutter/material.dart';

import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/category_icon_tile.dart';
import '../../../../data/db/app_database.dart';
import '../../../../data/models/display_style.dart';

/// Expense categories: 5 columns of square tiles. The first 9 are
/// shown, plus a "More" tile that opens the full list.
class ExpenseCategoryGrid extends StatelessWidget {
  const ExpenseCategoryGrid({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelect,
    required this.onMore,
  });

  final List<CategoryRow> categories;
  final int? selectedId;
  final ValueChanged<int> onSelect;
  final VoidCallback onMore;

  static const quickCount = 9;

  @override
  Widget build(BuildContext context) {
    final shown = quickTiles(categories, selectedId, quickCount);
    return _Grid(
      columns: 5,
      spacing: 6,
      children: [
        for (final c in shown)
          _ExpenseTile(
            category: c,
            selected: c.id == selectedId,
            onTap: () => onSelect(c.id),
          ),
        _MoreTile(onTap: onMore),
      ],
    );
  }
}

/// Income sources: 3 columns of wide tiles. If there are more than 6,
/// the last tile becomes "More".
class IncomeCategoryGrid extends StatelessWidget {
  const IncomeCategoryGrid({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelect,
    required this.onMore,
  });

  final List<CategoryRow> categories;
  final int? selectedId;
  final ValueChanged<int> onSelect;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final needsMore = categories.length > 6;
    final shown = needsMore
        ? quickTiles(categories, selectedId, 5)
        : categories;
    return _Grid(
      columns: 3,
      spacing: 8,
      children: [
        for (final c in shown)
          _IncomeTile(
            category: c,
            selected: c.id == selectedId,
            onTap: () => onSelect(c.id),
          ),
        if (needsMore) _MoreTile(onTap: onMore, wide: true),
      ],
    );
  }
}

/// The first [count] categories. If the selected one is further down the
/// list (picked from "More"), it takes the last place so it stays visible.
List<CategoryRow> quickTiles(
  List<CategoryRow> all,
  int? selectedId,
  int count,
) {
  final first = all.take(count).toList();
  if (selectedId == null || first.any((c) => c.id == selectedId)) return first;
  final selected = all.where((c) => c.id == selectedId);
  if (selected.isEmpty) return first;
  return [...first.take(count - 1), selected.first];
}

class _Grid extends StatelessWidget {
  const _Grid({
    required this.columns,
    required this.spacing,
    required this.children,
  });

  final int columns;
  final double spacing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final rowChildren = children.skip(i).take(columns).toList();
      rows.add(
        Row(
          children: [
            for (var j = 0; j < columns; j++) ...[
              if (j > 0) SizedBox(width: spacing),
              Expanded(
                child: j < rowChildren.length
                    ? rowChildren[j]
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      );
    }
    return Column(
      children: [
        for (final (i, row) in rows.indexed) ...[
          if (i > 0) SizedBox(height: spacing),
          row,
        ],
      ],
    );
  }
}

/// Shared look of a selectable tile: white, or tinted with a colored
/// border when selected.
class _TileFrame extends StatelessWidget {
  const _TileFrame({
    required this.category,
    required this.selected,
    required this.onTap,
    required this.height,
    required this.child,
  });

  final CategoryRow category;
  final bool selected;
  final VoidCallback onTap;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final tint = category.color.resolve(brightness);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: selected ? BorderSide(color: tint, width: 2) : BorderSide.none,
    );
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: category.name,
      excludeSemantics: true,
      child: Material(
        color: selected
            ? tint.withValues(alpha: CategoryColor.tileAlpha(brightness))
            : context.colors.surface,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: SizedBox(height: height, child: child),
        ),
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final CategoryRow category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _TileFrame(
      category: category,
      selected: selected,
      onTap: onTap,
      height: 74,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CategoryIconTile(
            icon: category.icon,
            color: category.color,
            size: 34,
            iconSize: 17,
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FittedBox(
              // Long names like "Transportation" shrink to fit the tile.
              fit: BoxFit.scaleDown,
              child: Text(
                category.name,
                maxLines: 1,
                style: selected ? AppText.tiny11Strong : AppText.tiny11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomeTile extends StatelessWidget {
  const _IncomeTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final CategoryRow category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _TileFrame(
      category: category,
      selected: selected,
      onTap: onTap,
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            CategoryIconTile(
              icon: category.icon,
              color: category.color,
              size: 32,
              iconSize: 16,
              radius: 9,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FittedBox(
                // Shrink long names instead of cutting them.
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  category.name,
                  maxLines: 1,
                  style: selected ? AppText.label14Strong : AppText.label14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dashed tile that opens the full category list.
class _MoreTile extends StatelessWidget {
  const _MoreTile({required this.onTap, this.wide = false});

  final VoidCallback onTap;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final icon = Container(
      width: wide ? 32 : 34,
      height: wide ? 32 : 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(wide ? 9 : 10),
      ),
      child: AppIcon(AppIcons.plus, size: 17, color: c.textSecondary),
    );
    return Semantics(
      container: true,
      button: true,
      label: 'More categories',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: CustomPaint(
          painter: _DashedBorderPainter(color: c.divider),
          child: SizedBox(
            height: wide ? 56 : 74,
            child: wide
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        icon,
                        const SizedBox(width: 8),
                        Text(
                          'More',
                          style: AppText.label14.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      icon,
                      const SizedBox(height: 6),
                      Text(
                        'More',
                        style: AppText.tiny11.copyWith(color: c.textSecondary),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// 1 px dashed rounded border, like CSS `border: 1px dashed`.
class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(0.5),
      const Radius.circular(14),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 7) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}
