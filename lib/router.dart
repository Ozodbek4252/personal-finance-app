import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'dev/design_preview_page.dart';
import 'data/models/transaction_kind.dart';
import 'features/add_transaction/ui/add_transaction_page.dart';
import 'features/categories/ui/categories_page.dart';
import 'features/categories/ui/category_form_page.dart';
import 'features/currencies/ui/currencies_page.dart';
import 'features/dashboard/ui/dashboard_page.dart';
import 'features/edit_transaction/ui/edit_transaction_page.dart';
import 'features/exchange/ui/edit_exchange_page.dart';
import 'features/exchange/ui/exchange_detail_page.dart';
import 'features/monthly_overview/ui/monthly_overview_page.dart';
import 'features/payment_methods/ui/payment_methods_page.dart';
import 'features/settings/ui/settings_page.dart';
import 'features/statistics/ui/statistics_page.dart';
import 'features/transaction_detail/ui/transaction_detail_page.dart';
import 'features/transactions/ui/transactions_page.dart';
import 'shell/app_shell.dart';

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
  static const buyDollars = '/add?type=exchange';
  static const sellDollars = '/add?type=exchange&sell=true';

  static const monthlyOverview = '/monthly';
  static const categories = '/categories';
  static const paymentMethods = '/payment-methods';
  static const currencies = '/currencies';
  static const newCategory = '/categories/new';
  static String editCategory(int id) => '/categories/$id/edit';
  static String transactionDetail(int id) => '/transaction/$id';
  static String editTransaction(int id) => '/transaction/$id/edit';
  static String exchangeDetail(int id) => '/exchange/$id';
  static String editExchange(int id) => '/exchange/$id/edit';

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
            startWithExchange: state.uri.queryParameters['type'] == 'exchange',
            sellDollars: state.uri.queryParameters['sell'] == 'true',
          ),
        ),
      ),
      GoRoute(
        path: '/transaction/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => TransactionDetailPage(
          id: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
        ),
        routes: [
          GoRoute(
            path: 'edit',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => EditTransactionPage(
              id: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/exchange/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ExchangeDetailPage(
          id: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
        ),
        routes: [
          GoRoute(
            path: 'edit',
            parentNavigatorKey: _rootNavigatorKey,
            pageBuilder: (context, state) => MaterialPage(
              fullscreenDialog: true,
              child: EditExchangePage(
                id: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: Routes.monthlyOverview,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MonthlyOverviewPage(),
      ),
      GoRoute(
        path: Routes.categories,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CategoriesPage(),
        routes: [
          GoRoute(
            path: 'new',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => CategoryFormPage(
              initialKind: state.uri.queryParameters['kind'] == 'income'
                  ? TransactionKind.income
                  : TransactionKind.expense,
            ),
          ),
          GoRoute(
            path: ':id/edit',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => CategoryFormPage(
              categoryId: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
            ),
          ),
        ],
      ),
      GoRoute(
        path: Routes.paymentMethods,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PaymentMethodsPage(),
      ),
      GoRoute(
        path: Routes.currencies,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CurrenciesPage(),
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
