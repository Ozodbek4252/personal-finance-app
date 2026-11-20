import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/category_chip.dart';
import '../../../../data/db/app_database.dart';
import '../../../../data/models/transaction_kind.dart';
import '../../../../data/providers/data_providers.dart';
import '../../providers/statistics_providers.dart';

/// "Exclude categories" chip, then one "Without Home ✕" chip for each
/// category left out of the statistics.
class ExcludedCategoriesRow extends ConsumerWidget {
  const ExcludedCategoriesRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final excluded = ref.watch(statExcludedCategoriesProvider);
    final notifier = ref.read(statExcludedCategoriesProvider.notifier);
    final names = {
      for (final c
          in ref.watch(categoriesProvider(TransactionKind.expense)).value ??
              const <CategoryRow>[])
        c.id: c.name,
    };
    return ChipRow(
      children: [
        AppChip(
          label: excluded.isEmpty ? 'Exclude categories' : 'Edit',
          leadingIcon: AppIcons.filter,
          onTap: () => showExcludeCategoriesSheet(context),
        ),
        for (final id in excluded)
          AppChip(
            label: 'Without ${names[id] ?? 'category'}',
            selected: true,
            trailingIcon: AppIcons.close,
            semanticLabel: 'Include ${names[id] ?? 'category'} again',
            onTap: () => notifier.toggle(id),
          ),
      ],
    );
  }
}

/// Sheet to pick expense categories to leave out of the statistics.
Future<void> showExcludeCategoriesSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: context.colors.background,
    // The sheet draws its own handle.
    showDragHandle: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => const _ExcludeSheet(),
  );
}

class _ExcludeSheet extends ConsumerWidget {
  const _ExcludeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final excluded = ref.watch(statExcludedCategoriesProvider);
    final notifier = ref.read(statExcludedCategoriesProvider.notifier);
    final categories =
        ref.watch(categoriesProvider(TransactionKind.expense)).value ??
        const <CategoryRow>[];

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Exclude categories',
                      style: AppText.title20.copyWith(letterSpacing: 0),
                    ),
                  ),
                  TextButton(
                    onPressed: excluded.isEmpty ? null : notifier.clear,
                    child: Text(
                      'Show all',
                      style: AppText.body15.copyWith(
                        color: excluded.isEmpty
                            ? c.textTertiary
                            : c.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
              child: Text(
                'Picked categories are left out of every number and chart '
                'on Statistics. Your transactions do not change.',
                style: AppText.caption13Regular.copyWith(
                  color: c.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final cat in categories)
                      CategoryChip(
                        category: cat,
                        selected: excluded.contains(cat.id),
                        onTap: () => notifier.toggle(cat.id),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: PrimaryButton(
                label: excluded.isEmpty
                    ? 'Done'
                    : 'Done · ${excluded.length} left out',
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
