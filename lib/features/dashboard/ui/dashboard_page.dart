import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_card.dart';
import '../domain/dashboard_data.dart';
import '../providers/dashboard_providers.dart';
import 'widgets/balance_card.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/empty_dashboard.dart';
import 'widgets/month_summary_cards.dart';
import 'widgets/recent_section.dart';
import 'widgets/spending_sections.dart';

/// Home tab: balance, this month's numbers, spending and recent items.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dashboardProvider);
    final rateInsight = ref.watch(dollarRateInsightProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: DashboardHeader()),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                // Room for the bottom nav that floats over the page.
                28 + MediaQuery.paddingOf(context).bottom,
              ),
              sliver: SliverList.list(
                children: switch (data) {
                  AsyncData(:final value) => _sections(value, rateInsight),
                  AsyncError(:final error) => [_ErrorCard(error: error)],
                  _ => const [BalanceCard()],
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _sections(DashboardData data, Insight? rateInsight) {
    const gap = SizedBox(height: 16);
    final insights = [...data.insights, ?rateInsight];
    if (!data.hasAnyTransactions) {
      return [
        const BalanceCard(),
        gap,
        IncomeExpenseCards(data: data),
        gap,
        const EmptyDashboardCard(),
      ];
    }
    return [
      const BalanceCard(),
      gap,
      IncomeExpenseCards(data: data),
      gap,
      SavingsCard(data: data),
      if (data.categories.isNotEmpty) ...[
        gap,
        SpendingByCategorySection(data: data),
      ],
      gap,
      SpendingTrendSection(data: data),
      if (insights.isNotEmpty) ...[gap, InsightsSection(insights: insights)],
      gap,
      const RecentSection(),
    ];
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Text(
        'Could not load your data. Please restart the app.\n$error',
        style: AppText.label14.copyWith(color: context.colors.expense),
      ),
    );
  }
}
