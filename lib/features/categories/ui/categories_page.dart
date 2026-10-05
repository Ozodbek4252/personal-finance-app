import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/category_icon_tile.dart';
import '../../../core/widgets/dashed_border.dart';
import '../../../core/time/clock.dart';
import '../../../data/db/app_database.dart';
import '../../../data/models/display_style.dart';
import '../../../data/models/transaction_kind.dart';
import '../../../data/providers/data_providers.dart';
import '../../../router.dart';

/// How many categories of each kind show as tiles on the add screen.
int quickAddSlots(TransactionKind kind) =>
    kind == TransactionKind.expense ? 9 : 6;

/// List of expense and income categories. Drag to reorder; the first
/// ones are the quick-add tiles on the add screen.
class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Key by the month start: a key that changes each build (like "now")
    // would create a new provider on every frame.
    final month = monthStart(ref.watch(clockProvider).now());
    final monthItems = ref.watch(monthTransactionsProvider(month)).value;
    final counts = <int, int>{};
    for (final t in monthItems ?? const []) {
      counts.update(t.category.id, (n) => n + 1, ifAbsent: () => 1);
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onBack: () => context.pop(),
              onNew: () => context.push(Routes.newCategory),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                children: [
                  const _InfoNote(),
                  const SizedBox(height: 16),
                  _CategoryGroup(
                    kind: TransactionKind.expense,
                    title: 'Expense categories',
                    counts: counts,
                  ),
                  const SizedBox(height: 16),
                  _CategoryGroup(
                    kind: TransactionKind.income,
                    title: 'Income categories',
                    counts: counts,
                  ),
                  const SizedBox(height: 16),
                  _NewCategoryButton(
                    onTap: () => context.push(Routes.newCategory),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.onNew});

  final VoidCallback onBack;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Align(
                alignment: Alignment.centerLeft,
                child: CircleIconButton.raised(
                  icon: AppIcons.chevronLeft,
                  semanticLabel: 'Back',
                  onTap: onBack,
                ),
              ),
            ),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  'Categories',
                  textAlign: TextAlign.center,
                  style: AppText.heading17,
                ),
              ),
            ),
            SizedBox(
              width: 100,
              child: Align(
                alignment: Alignment.centerRight,
                child: CircleIconButton.raised(
                  icon: AppIcons.plus,
                  semanticLabel: 'New category',
                  onTap: onNew,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(AppIcons.info, size: 18, color: c.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Drag to reorder. The first 9 expense categories appear on '
              'the add screen. Default categories can be renamed or removed.',
              style: AppText.caption13Regular.copyWith(
                color: c.textSecondary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "EXPENSE CATEGORIES · 11" and a card with rows you can drag.
class _CategoryGroup extends ConsumerStatefulWidget {
  const _CategoryGroup({
    required this.kind,
    required this.title,
    required this.counts,
  });

  final TransactionKind kind;
  final String title;
  final Map<int, int> counts;

  @override
  ConsumerState<_CategoryGroup> createState() => _CategoryGroupState();
}

class _CategoryGroupState extends ConsumerState<_CategoryGroup> {
  /// The order while dragging, before the database has caught up.
  List<CategoryRow>? _pending;

  Future<void> _reorder(List<CategoryRow> list, int from, int to) async {
    final items = [...list];
    items.insert(to, items.removeAt(from));
    setState(() => _pending = items);
    await ref
        .read(categoryRepositoryProvider)
        .reorder(items.map((c) => c.id).toList());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final saved = ref.watch(categoriesProvider(widget.kind)).value ?? const [];
    // Keep the dragged order until the saved list matches it.
    final pending = _pending;
    final list =
        pending != null &&
            pending.map((e) => e.id).join() != saved.map((e) => e.id).join()
        ? pending
        : saved;
    final quick = widget.kind == TransactionKind.expense
        ? quickAddSlots(widget.kind)
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 32),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      widget.title.toUpperCase(),
                      style: AppText.overline13.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ),
                Text(
                  '${list.length}',
                  style: AppText.caption13Regular.copyWith(
                    color: c.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: list.length,
            onReorderItem: (from, to) => _reorder(list, from, to),
            proxyDecorator: (child, _, _) => Material(
              color: c.surface,
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              child: child,
            ),
            itemBuilder: (context, i) => _CategoryRowTile(
              key: ValueKey(list[i].id),
              index: i,
              category: list[i],
              count: widget.counts[list[i].id] ?? 0,
              quickAdd: i < quick,
              showDivider: i > 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryRowTile extends StatelessWidget {
  const _CategoryRowTile({
    super.key,
    required this.index,
    required this.category,
    required this.count,
    required this.quickAdd,
    required this.showDivider,
  });

  final int index;
  final CategoryRow category;
  final int count;
  final bool quickAdd;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: showDivider ? Border(top: BorderSide(color: c.divider)) : null,
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: Semantics(
              container: true,
              label: 'Reorder ${category.name}',
              child: SizedBox(
                width: 28,
                height: 44,
                child: Center(
                  child: AppIcon(
                    AppIcons.dragHandle,
                    size: 18,
                    strokeWidth: 2.6,
                    color: c.textTertiary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          CategoryIconTile(icon: category.icon, color: category.color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.name, style: AppText.body15),
                const SizedBox(height: 2),
                Text(
                  count == 0 ? 'None this month' : '$count this month',
                  style: AppText.small12Regular.copyWith(color: c.textTertiary),
                ),
              ],
            ),
          ),
          if (quickAdd)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: c.surfaceMuted,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Quick add',
                style: AppText.tiny11Strong.copyWith(color: c.textSecondary),
              ),
            ),
          CircleIconButton(
            icon: AppIcons.pencil,
            iconSize: 18,
            color: c.textSecondary,
            semanticLabel: 'Edit ${category.name}',
            onTap: () => context.push(Routes.editCategory(category.id)),
          ),
        ],
      ),
    );
  }
}

/// Dashed "+ New category" button under the lists.
class _NewCategoryButton extends StatelessWidget {
  const _NewCategoryButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      label: 'New category',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.field),
        child: DashedBorder(
          color: c.border,
          radius: AppRadius.field,
          child: SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppIcon(AppIcons.plus, size: 18),
                const SizedBox(width: 8),
                Text('New category', style: AppText.body15Strong),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
