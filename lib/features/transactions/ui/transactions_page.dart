import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/date_format.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/category_icon_tile.dart';
import '../../../core/widgets/option_sheet.dart';
import '../../../core/widgets/page_title.dart';
import '../../../core/widgets/search_field.dart';
import '../../../data/db/app_database.dart';
import '../../../data/models/display_style.dart';
import '../../../data/models/transaction_details.dart';
import '../../../data/models/transaction_kind.dart';
import '../../../data/providers/data_providers.dart';
import '../../../router.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../domain/transaction_filter.dart';
import '../providers/transactions_providers.dart';
import 'widgets/transaction_list_parts.dart';
import 'widgets/transaction_tile.dart';

/// Transactions tab: search, filter chips, totals and the list.
class TransactionsPage extends ConsumerWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(transactionFilterProvider);
    final notifier = ref.read(transactionFilterProvider.notifier);
    final list = ref.watch(transactionListProvider);
    final now = ref.watch(clockProvider).now();
    final categoryNames = <int, String>{
      for (final k in TransactionKind.values)
        for (final c in ref.watch(categoriesProvider(k)).value ?? const [])
          c.id: c.name,
    };

    const gap = SliverToBoxAdapter(child: SizedBox(height: 16));
    const side = EdgeInsets.symmetric(horizontal: 16);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: PageTitle(
                'Transactions',
                trailing: Row(
                  children: [
                    CircleIconButton.raised(
                      icon: AppIcons.sort,
                      semanticLabel: 'Sort',
                      onTap: () => _pickSort(context, ref),
                    ),
                    const SizedBox(width: 8),
                    CircleIconButton.raised(
                      icon: AppIcons.filter,
                      semanticLabel: 'Filters',
                      onTap: () => ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('The filter sheet comes in Task 8.'),
                          ),
                        ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverPadding(
              padding: side,
              sliver: SliverToBoxAdapter(
                child: SearchField(
                  value: filter.query,
                  onChanged: notifier.setQuery,
                  hint: 'Search notes, categories, amounts',
                  semanticLabel: 'Search transactions',
                ),
              ),
            ),
            gap,
            SliverToBoxAdapter(
              child: ChipRow(
                children: [
                  for (final t in TypeFilter.values)
                    AppChip(
                      label: t.label,
                      selected: filter.type == t,
                      onTap: () => notifier.setType(t),
                    ),
                  AppChip(
                    label: _periodLabel(filter.period),
                    leadingIcon: AppIcons.calendar,
                    trailingIcon: AppIcons.chevronDown,
                    onTap: () => _pickPeriod(context, ref),
                  ),
                  AppChip(
                    label: _categoryLabel(filter.categoryIds, categoryNames),
                    selected: filter.categoryIds.isNotEmpty,
                    trailingIcon: AppIcons.chevronDown,
                    onTap: () => _pickCategory(context, ref),
                  ),
                ],
              ),
            ),
            gap,
            ...switch (list) {
              AsyncData(:final value) => _listSlivers(context, value, now),
              AsyncError(:final error) => [
                SliverPadding(
                  padding: side,
                  sliver: SliverToBoxAdapter(
                    child: _MessageCard(text: 'Could not load: $error'),
                  ),
                ),
              ],
              _ => const <Widget>[],
            },
            SliverToBoxAdapter(
              // Room for the bottom nav that floats over the page.
              child: SizedBox(
                height: 24 + MediaQuery.paddingOf(context).bottom,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _listSlivers(
    BuildContext context,
    TransactionListView view,
    DateTime now,
  ) {
    const side = EdgeInsets.symmetric(horizontal: 16);
    final header = SliverPadding(
      padding: side,
      sliver: SliverList.list(
        children: [
          InOutNetCard(view: view),
          const SizedBox(height: 16),
          Consumer(
            builder: (context, ref, _) => CountAndSortRow(
              count: view.items.length,
              sort: view.sort,
              onSort: () => _pickSort(context, ref),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );

    if (view.items.isEmpty) {
      return [
        header,
        const SliverPadding(
          padding: side,
          sliver: SliverToBoxAdapter(
            child: _MessageCard(text: 'No transactions match these filters.'),
          ),
        ),
      ];
    }

    void open(TransactionDetails t) =>
        context.push(Routes.transactionDetail(t.id));

    if (!view.sort.groupsByDay) {
      return [
        header,
        SliverPadding(
          padding: side,
          sliver: SliverToBoxAdapter(
            child: _TileCard(
              items: view.items,
              timeText: (t) => DateText.dayMonthTime(t.occurredAt),
              onTap: open,
            ),
          ),
        ),
      ];
    }

    final days = view.days;
    return [
      header,
      SliverPadding(
        padding: side,
        sliver: SliverList.builder(
          itemCount: days.length,
          itemBuilder: (context, i) => Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DayHeader(group: days[i], now: now),
                const SizedBox(height: 8),
                _TileCard(
                  items: days[i].items,
                  timeText: (t) => DateText.time(t.occurredAt),
                  onTap: open,
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  static String _periodLabel(DateRange? period) {
    if (period == null) return 'All time';
    if (period.isWholeMonth) return DateText.month(period.from);
    return DateText.range(
      period.from,
      period.to.subtract(const Duration(days: 1)),
    );
  }

  static String _categoryLabel(Set<int> ids, Map<int, String> names) {
    if (ids.isEmpty) return 'Category';
    if (ids.length == 1) return names[ids.first] ?? 'Category';
    return '${ids.length} categories';
  }

  Future<void> _pickSort(BuildContext context, WidgetRef ref) async {
    final picked = await showOptionSheet<SortOrder>(
      context,
      title: 'Sort by',
      selected: ref.read(transactionFilterProvider).sort,
      options: [
        for (final s in SortOrder.values) SheetOption(value: s, label: s.label),
      ],
    );
    if (picked != null) {
      ref.read(transactionFilterProvider.notifier).setSort(picked);
    }
  }

  Future<void> _pickPeriod(BuildContext context, WidgetRef ref) async {
    // A wrapper, so "All time" (null) can be told apart from "dismissed".
    final picked = await showOptionSheet<({DateRange? range})>(
      context,
      title: 'Period',
      selected: (range: ref.read(transactionFilterProvider).period),
      options: [
        const SheetOption(value: (range: null), label: 'All time'),
        for (final m in ref.read(selectableMonthsProvider))
          SheetOption(
            value: (range: DateRange.month(m)),
            label: DateText.monthYear(m),
          ),
      ],
    );
    if (picked != null) {
      ref.read(transactionFilterProvider.notifier).setPeriod(picked.range);
    }
  }

  Future<void> _pickCategory(BuildContext context, WidgetRef ref) async {
    final filter = ref.read(transactionFilterProvider);
    final kinds = switch (filter.type) {
      TypeFilter.expenses => [TransactionKind.expense],
      TypeFilter.income => [TransactionKind.income],
      TypeFilter.all => TransactionKind.values,
    };
    final categories = <CategoryRow>[
      for (final k in kinds) ...?ref.read(categoriesProvider(k)).value,
    ];
    final picked = await showOptionSheet<int>(
      context,
      title: 'Category',
      selected: filter.categoryIds.length == 1 ? filter.categoryIds.first : -1,
      options: [
        const SheetOption(value: -1, label: 'All categories'),
        for (final c in categories)
          SheetOption(
            value: c.id,
            label: c.name,
            subtitle: c.kind == TransactionKind.income ? 'Income' : null,
            leading: CategoryIconTile(icon: c.icon, color: c.color),
          ),
      ],
    );
    if (picked != null) {
      ref
          .read(transactionFilterProvider.notifier)
          .setCategories(picked == -1 ? {} : {picked});
    }
  }
}

/// White card with transaction rows and thin lines between them.
class _TileCard extends StatelessWidget {
  const _TileCard({
    required this.items,
    required this.timeText,
    required this.onTap,
  });

  final List<TransactionDetails> items;
  final String Function(TransactionDetails) timeText;
  final void Function(TransactionDetails) onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          for (final (i, t) in items.indexed)
            TransactionTile(
              item: t,
              showDivider: i > 0,
              timeText: timeText(t),
              onTap: () => onTap(t),
            ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppText.label14.copyWith(color: context.colors.textSecondary),
      ),
    );
  }
}
