import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/icons/app_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../core/theme/app_tokens.dart';
import '../core/widgets/app_icon.dart';

/// One tab in [AppBottomNav].
class NavTab {
  const NavTab(this.label, this.icon);

  final String label;
  final AppIconData icon;
}

/// Bottom navigation from the design: 4 tabs with a round "+" button
/// in the middle that sticks out above the bar.
///
/// Use it with `Scaffold(extendBody: true)`. The top part above the bar
/// is see-through, so taps there go to the page behind it.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onAddPressed,
  }) : assert(tabs.length == 4, 'The design has 2 tabs on each side.');

  final List<NavTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onAddPressed;

  /// How far the "+" button sticks out above the bar.
  static const fabOverlap = 30.0;
  static const fabSize = 60.0;

  /// Bar height without the bottom safe area.
  static const barHeight = 62.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // The design keeps 22 px below the tabs for the home indicator.
    // Phones without one still get a little space.
    final bottomInset = math.max(MediaQuery.viewPaddingOf(context).bottom, 8.0);

    Widget tab(int index) => Expanded(
      child: _NavItem(
        tab: tabs[index],
        selected: index == currentIndex,
        onTap: () => onTabSelected(index),
      ),
    );

    return SizedBox(
      height: fabOverlap + barHeight + bottomInset,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: fabOverlap,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(8, 6, 8, bottomInset),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(top: BorderSide(color: c.divider)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [tab(0), tab(1), const Spacer(), tab(2), tab(3)],
              ),
            ),
          ),
          Positioned(
            top: 6 + fabOverlap - fabSize / 2,
            left: 0,
            right: 0,
            child: Center(child: _AddButton(onPressed: onAddPressed)),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final NavTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = selected ? c.accent : c.textTertiary;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: tab.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: SizedBox(
          height: 52,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(
                tab.icon,
                size: 22,
                color: color,
                strokeWidth: selected ? 2 : 1.8,
              ),
              const SizedBox(height: 4),
              Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (selected ? AppText.tiny11Strong : AppText.tiny11)
                    .copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const size = AppBottomNav.fabSize;
    return Semantics(
      container: true,
      button: true,
      label: 'Add transaction',
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            // 5 px ring in the page color, so the button looks cut out
            // of the bar. Drawn first so the soft shadow sits on top.
            BoxShadow(color: c.background, spreadRadius: 5),
            ...AppShadows.fab,
          ],
        ),
        child: Material(
          color: c.primary,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Center(
              child: AppIcon(
                AppIcons.plus,
                size: 28,
                color: c.onPrimary,
                strokeWidth: 2.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
