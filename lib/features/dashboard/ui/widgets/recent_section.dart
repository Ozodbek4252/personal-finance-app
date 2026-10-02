import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../data/providers/data_providers.dart';
import '../../../../router.dart';
import '../../../transactions/ui/widgets/transaction_tile.dart';

/// "Recent": the newest four transactions.
class RecentSection extends ConsumerWidget {
  const RecentSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(recentTransactionsProvider).value ?? const [];
    if (items.isEmpty) return const SizedBox.shrink();
    final now = ref.watch(clockProvider).now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Recent',
          actionLabel: 'See all',
          onAction: () => context.go(Routes.transactions),
        ),
        const SizedBox(height: 4),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              for (final (i, item) in items.indexed)
                TransactionTile(
                  item: item,
                  showDivider: i > 0,
                  timeText: TransactionTile.mixedDayTime(item, now),
                  onTap: () => context.push(Routes.transactionDetail(item.id)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
