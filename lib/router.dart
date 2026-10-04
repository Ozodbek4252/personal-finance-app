import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'dev/design_preview_page.dart';
import 'data/models/transaction_kind.dart';
import 'features/add_transaction/ui/add_transaction_page.dart';
import 'features/dashboard/ui/dashboard_page.dart';
import 'features/settings/ui/settings_page.dart';
import 'features/statistics/ui/statistics_page.dart';
import 'features/transactions/ui/transactions_page.dart';
import 'shell/app_shell.dart';
import 'shell/placeholder_body.dart';

/// All route paths in one place.
abstract final class Routes {
  // Tabs.
  static const home = '/';
  static const transactions = '/transactions';
  static const statistics = '/statistics';
  static const settings = '/settings';

  // Full-screen pages on top of the tabs.
  static const add = '/add';
  static const addExpense = '/add?type=expense';
  static const addIncome = '/add?type=income';

  static const monthlyOverview = '/monthly';
  static const categories = '/categories';
  static String transactionDetail(int id) => '/transaction/$id';

  static const designPreview = '/dev/preview';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: Routes.home,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          _tab(Routes.home, const DashboardPage()),
          _tab(Routes.transactions, const TransactionsPage()),
          _tab(Routes.statistics, const StatisticsPage()),
          _tab(Routes.settings, const SettingsPage()),
        ],
      ),
      // Pages below cover the bottom nav, so they use the root navigator.
      GoRoute(
        path: Routes.add,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => MaterialPage(
          fullscreenDialog: true,
          child: AddTransactionPage(
            initialKind: state.uri.queryParameters['type'] == 'income'
                ? TransactionKind.income
                : TransactionKind.expense,
          ),
        ),
      ),
      GoRoute(
        path: '/transaction/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => PlaceholderPage(
          title: 'Transaction',
          message:
              'Transaction ${state.pathParameters['id']} details are built '
              'in Task 9.',
        ),
      ),
      GoRoute(
        path: Routes.monthlyOverview,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PlaceholderPage(
          title: 'Monthly overview',
          message: 'The Monthly overview is built in Task 12.',
        ),
      ),
      GoRoute(
        path: Routes.categories,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PlaceholderPage(
          title: 'Categories',
          message: 'Managing categories is built in Task 13.',
        ),
      ),
      GoRoute(
        path: Routes.designPreview,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DesignPreviewPage(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

StatefulShellBranch _tab(String path, Widget page) => StatefulShellBranch(
  routes: [
    GoRoute(
      path: path,
      // No slide animation when switching tabs.
      pageBuilder: (context, state) => NoTransitionPage(child: page),
    ),
  ],
);
