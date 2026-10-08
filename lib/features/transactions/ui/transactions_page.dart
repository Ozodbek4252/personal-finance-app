import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/date_format.dart';
import '../../../core/format/money_format.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/category_icon_tile.dart';
import '../../../core/widgets/option_sheet.dart';
import '../../../core/widgets/page_title.dart';
import '../../../core/widgets/search_field.dart';
import '../../../data/db/app_database.dart';
import '../../../data/models/display_style.dart';
import '../../../data/models/transaction_kind.dart';
import '../../../data/providers/data_providers.dart';
import '../../../router.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../domain/list_entry.dart';
import '../domain/transaction_filter.dart';
import '../providers/transactions_providers.dart';
import 'widgets/exchange_tile.dart';
import 'widgets/filter_sheet.dart';
import 'widgets/transaction_list_parts.dart';
import 'widgets/transaction_tile.dart';

/// Transactions tab.
///
/// Normal mode shows In/Out/Net totals and a list grouped by day.
/// When search text, a type or a category is set, it switches to
/// results mode: removable filter chips, "N results" and a flat list
/// with the search text highlighted.
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
                      onTap: () => showFilterSheet(context),
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
                children: filter.hasFilters
                    ? _activeChips(context, ref, filter, categoryNames)
                    : _browseChips(context, ref, filter, categoryNames),
              ),
            ),
            gap,
            ...switch (list) {
              AsyncData(:final value) => _listSlivers(
                context,
                ref,
                value,
                filter,
                categoryNames,
                now,
              ),
              AsyncError(:final error) => [
                SliverPadding(
                  padding: side,
                  sliver: SliverToBoxAdapter(
                    child: AppCard(child: Text('Could not load: $error')),
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

  /// Chips in normal mode: type, period and category pickers.
  List<Widget> _browseChips(
    BuildContext context,
    WidgetRef ref,
    TransactionFilter filter,
    Map<int, String> names,
  ) {
    final notifier = ref.read(transactionFilterProvider.notifier);
    return [
      for (final t in TypeFilter.values)
        AppChip(
          label: t.label,
          leadingIcon: t == TypeFilter.exchanges ? AppIcons.exchange : null,
          selected: filter.type == t,
          onTap: () => notifier.setType(t),
        ),
      AppChip(
        label: periodLabel(filter.period),
        leadingIcon: AppIcons.calendar,
        trailingIcon: AppIcons.chevronDown,
        onTap: () => _pickPeriod(context, ref),
      ),
      AppChip(
        label: 'Category',
        trailingIcon: AppIcons.chevronDown,
        onTap: () => _pickCategory(context, ref),
      ),
    ];
  }

  /// Chips in results mode: each active filter with ✕ to remove it,
  /// then the sort order.
  List<Widget> _activeChips(
    BuildContext context,
    WidgetRef ref,
    TransactionFilter filter,
    Map<int, String> names,
  ) {
    final notifier = ref.read(transactionFilterProvider.notifier);
    final period = filter.period;
    return [
      if (filter.type != TypeFilter.all)
        AppChip(
          label: filter.type.label,
          selected: true,
          trailingIcon: AppIcons.close,
          semanticLabel: 'Remove filter ${filter.type.label}',
          onTap: () => notifier.setType(TypeFilter.all),
        ),
      for (final id in filter.categoryIds)
        AppChip(
          label: names[id] ?? 'Category',
          selected: true,
          trailingIcon: AppIcons.close,
          semanticLabel: 'Remove filter ${names[id] ?? 'category'}',
          onTap: () =>
              notifier.setCategories({...filter.categoryIds}..remove(id)),
        ),
      if (period != null)
        AppChip(
          label: rangeLabel(period),
          selected: true,
          leadingIcon: AppIcons.calendar,
          trailingIcon: AppIcons.close,
          semanticLabel: 'Remove date filter ${rangeLabel(period)}',
          onTap: () => notifier.setPeriod(null),
        )
      else
        AppChip(
          label: 'All time',
          leadingIcon: AppIcons.calendar,
          trailingIcon: AppIcons.chevronDown,
          onTap: () => _pickPeriod(context, ref),
        ),
      AppChip(
        label: filter.sort.shortLabel,
        leadingIcon: AppIcons.sort,
        trailingIcon: AppIcons.chevronDown,
        onTap: () => _pickSort(context, ref),
      ),
    ];
  }

  List<Widget> _listSlivers(
    BuildContext context,
    WidgetRef ref,
    TransactionListView view,
    TransactionFilter filter,
    Map<int, String> names,
    DateTime now,
  ) {
    const side = EdgeInsets.symmetric(horizontal: 16);
    final notifier = ref.read(transactionFilterProvider.notifier);
    void open(ListEntry e) => context.push(switch (e) {
      TransactionEntry() => Routes.transactionDetail(e.id),
      ExchangeEntry() => Routes.exchangeDetail(e.id),
    });
    final usd = _usdText(ref);
    SliverPadding padded(Widget child) => SliverPadding(
      padding: side,
      sliver: SliverToBoxAdapter(child: child),
    );

    // ---- Results mode ----
    if (filter.hasFilters) {
      if (view.items.isEmpty) {
        final q = filter.query.trim();
        return [
          padded(
            EmptyResults(
              title: q.isEmpty
                  ? 'No matching transactions'
                  : 'No matches for “$q”',
              message: noResultsMessage(filter, names),
              onClearFilters: notifier.clearFilters,
              onSearchAllTime: filter.period == null
                  ? null
                  : () => notifier.setPeriod(null),
            ),
          ),
        ];
      }
      return [
        padded(ResultsHeader(view: view, query: filter.query)),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        padded(
          _TileCard(
            items: view.items,
            highlight: filter.query,
            timeText: (t) => DateText.dayMonthTime(t.occurredAt),
            onTap: open,
            usdText: usd,
          ),
        ),
        padded(
          Center(
            child: TextActionButton(
              label: 'Clear all filters',
              onPressed: notifier.reset,
            ),
          ),
        ),
      ];
    }

    // ---- Normal mode ----
    final header = SliverPadding(
      padding: side,
      sliver: SliverList.list(
        children: [
          InOutNetCard(view: view),
          const SizedBox(height: 16),
          CountAndSortRow(
            count: view.items.length,
            sort: view.sort,
            onSort: () => _pickSort(context, ref),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );

    if (view.items.isEmpty) {
      final period = filter.period;
      return [
        padded(
          EmptyResults(
            title: period == null
                ? 'No transactions yet'
                : 'No transactions in ${periodLabel(period)}',
            message: 'Tap + to add one, or pick another period.',
            onSearchAllTime: period == null
                ? null
                : () => notifier.setPeriod(null),
          ),
        ),
      ];
    }

    if (!view.sort.groupsByDay) {
      return [
        header,
        padded(
          _TileCard(
            items: view.items,
            timeText: (t) => DateText.dayMonthTime(t.occurredAt),
            onTap: open,
            usdText: usd,
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
                  usdText: usd,
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  /// "≈ $33" for a so'm amount when "Show USD in transaction list" is on.
  static String? Function(int som)? _usdText(WidgetRef ref) {
    final settings = ref.watch(currentSettingsProvider);
    final rate = ref.watch(usdRateProvider);
    if (!settings.showUsdInList || rate == null) return null;
    return (som) =>
        '≈ ${MoneyFormat.dollars(rate.toCents(som.abs()), round: settings.roundDollars)}';
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
    final categories = <CategoryRow>[
      for (final k in filter.type.kinds)
        ...?ref.read(categoriesProvider(k)).value,
    ];
    final picked = await showOptionSheet<int>(
      context,
      title: 'Category',
      options: [
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
      ref.read(transactionFilterProvider.notifier).setCategories({picked});
    }
  }
}

/// "September", "All time", or "1 – 30 Sep" for other ranges.
String periodLabel(DateRange? period) {
  if (period == null) return 'All time';
  if (period.isWholeMonth) return DateText.month(period.from);
  return rangeLabel(period);
}

/// "1 – 30 Sep" (the end of a range is exclusive, so show the day before).
String rangeLabel(DateRange period) =>
    DateText.range(period.from, period.to.subtract(const Duration(days: 1)));

/// "Nothing in income for September matches this search. …"
String noResultsMessage(TransactionFilter filter, Map<int, String> names) {
  final parts = <String>[
    switch (filter.type) {
      TypeFilter.income => 'in income',
      TypeFilter.expenses => 'in expenses',
      TypeFilter.exchanges => 'in exchanges',
      TypeFilter.all => '',
    },
    switch (filter.categoryIds.length) {
      0 => '',
      1 => 'in ${names[filter.categoryIds.first] ?? 'this category'}',
      final n => 'in $n categories',
    },
    if (filter.period case final p?) 'for ${periodLabel(p)}',
  ].where((p) => p.isNotEmpty);
  final scope = parts.isEmpty ? '' : ' ${parts.join(' ')}';
  return filter.query.trim().isEmpty
      ? 'Nothing$scope matches these filters. Try removing a filter.'
      : 'Nothing$scope matches this search. '
            'Try another word or remove a filter.';
}

/// White card with transaction and exchange rows and thin lines
/// between them.
class _TileCard extends StatelessWidget {
  const _TileCard({
    required this.items,
    required this.timeText,
    required this.onTap,
    this.highlight = '',
    this.usdText,
  });

  final List<ListEntry> items;
  final String Function(ListEntry) timeText;
  final void Function(ListEntry) onTap;
  final String highlight;

  /// Adds "≈ $" to transaction rows. Null shows no dollars.
  final String? Function(int som)? usdText;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          for (final (i, e) in items.indexed)
            switch (e) {
              TransactionEntry(:final item) => TransactionTile(
                item: item,
                showDivider: i > 0,
                timeText: timeText(e),
                highlight: highlight,
                usdText: usdText?.call(item.transaction.amount),
                onTap: () => onTap(e),
              ),
              ExchangeEntry(:final item) => ExchangeTile(
                item: item,
                showDivider: i > 0,
                timeText: timeText(e),
                highlight: highlight,
                onTap: () => onTap(e),
              ),
            },
        ],
      ),
    );
  }
}
