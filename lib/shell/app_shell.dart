import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/icons/app_icons.dart';
import '../router.dart';
import 'app_bottom_nav.dart';

/// Main screen frame: the current tab page plus the bottom nav.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  /// Keeps each tab's page alive, so scroll position is kept.
  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    NavTab('Home', AppIcons.home),
    NavTab('Transactions', AppIcons.list),
    NavTab('Statistics', AppIcons.chart),
    NavTab('Settings', AppIcons.settings),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Pages draw behind the see-through top part of the nav bar.
      // Scaffold adds the nav bar height to the bottom padding,
      // so lists can still scroll their last item into view.
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        tabs: _tabs,
        currentIndex: navigationShell.currentIndex,
        onTabSelected: (index) => navigationShell.goBranch(
          index,
          // Tapping the open tab again goes back to its first page.
          initialLocation: index == navigationShell.currentIndex,
        ),
        onAddPressed: () => context.push(Routes.addExpense),
      ),
    );
  }
}
