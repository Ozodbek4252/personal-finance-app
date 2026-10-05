import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/page_title.dart';
import '../../../core/widgets/segmented_tabs.dart';
import '../../../router.dart';
import '../domain/stat_period.dart';
import '../providers/statistics_providers.dart';
import 'widgets/stat_cards.dart';

/// Statistics tab: savings, spending by category and trends for a
/// week, month or year.
class StatisticsPage extends ConsumerWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(statPeriodProvider);
    final notifier = ref.read(statPeriodProvider.notifier);
    final data = ref.watch(statisticsProvider);
    final unitName = period.unit.name;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.only(
            bottom: 28 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            PageTitle(
              'Statistics',
              trailing: _MonthlyButton(
                onTap: () => context.push(Routes.monthlyOverview),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SegmentedTabs(
                options: [
                  for (final u in PeriodUnit.values) SegmentOption(u, u.label),
                ],
                selected: period.unit,
                onChanged: notifier.setUnit,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Row(
                children: [
                  CircleIconButton(
                    icon: AppIcons.chevronLeft,
                    semanticLabel: 'Previous $unitName',
                    onTap: notifier.previous,
                  ),
                  Expanded(
                    child: Text(
                      period.title,
                      textAlign: TextAlign.center,
                      style: AppText.body16Strong,
                    ),
                  ),
                  CircleIconButton(
                    icon: AppIcons.chevronRight,
                    semanticLabel: 'Next $unitName',
                    color: notifier.canGoNext
                        ? context.colors.textPrimary
                        : context.colors.textTertiary,
                    onTap: notifier.canGoNext ? notifier.next : null,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: switch (data) {
                AsyncData(:final value) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StatSavingsCard(data: value),
                    const SizedBox(height: AppSpacing.section),
                    SpendingByCategoryCard(data: value),
                    const SizedBox(height: AppSpacing.section),
                    IncomeVsExpensesCard(data: value),
                    const SizedBox(height: AppSpacing.section),
                    SpendingTrendCard(data: value),
                    const SizedBox(height: AppSpacing.section),
                    CategoryTrendCard(data: value),
                  ],
                ),
                AsyncError(:final error) => Text('Could not load: $error'),
                _ => const SizedBox(height: 400),
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// White "Monthly" pill that opens the Monthly overview.
class _MonthlyButton extends StatelessWidget {
  const _MonthlyButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      label: 'Monthly overview',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: AppShadows.card(Theme.of(context).brightness),
        ),
        child: Material(
          color: c.surface,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppIcon(AppIcons.calendar, size: 16),
                  const SizedBox(width: 6),
                  Text('Monthly', style: AppText.label14),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
