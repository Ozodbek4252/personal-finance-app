import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/date_format.dart';
import '../../../core/format/money_format.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/category_icon_tile.dart';
import '../../../core/widgets/option_sheet.dart';
import '../../../core/widgets/segmented_tabs.dart';
import '../../../data/db/app_database.dart';
import '../../../data/models/display_style.dart';
import '../../../data/models/transaction_kind.dart';
import '../../../data/providers/data_providers.dart';
import '../../../router.dart';
import '../../exchange/ui/exchange_form.dart';
import '../../receipts/receipt_widgets.dart';
import '../providers/add_transaction_controller.dart';
import 'widgets/amount_display.dart';
import 'widgets/category_grid.dart';
import 'widgets/note_sheet.dart';
import 'widgets/number_keypad.dart';

/// Tabs at the top of the add screen.
enum AddTab { expense, income, exchange }

/// Full-screen "Add expense" / "Add income" / "Exchange" page.
class AddTransactionPage extends ConsumerStatefulWidget {
  const AddTransactionPage({
    super.key,
    required this.initialKind,
    this.startWithExchange = false,
    this.sellDollars = false,
  });

  final TransactionKind initialKind;

  /// Open on the Exchange tab.
  final bool startWithExchange;

  /// With [startWithExchange]: sell dollars instead of buying them.
  final bool sellDollars;

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  late bool _exchange = widget.startWithExchange;

  TransactionKind get initialKind => widget.initialKind;

  @override
  Widget build(BuildContext context) {
    final provider = addTransactionProvider(initialKind);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final categories =
        ref.watch(categoriesProvider(state.kind)).value ?? const [];
    final methods = ref.watch(paymentMethodsProvider).value ?? const [];
    // The default payment method comes from settings.
    ref.watch(currentSettingsProvider);
    final methodId = controller.effectivePaymentMethodId();
    final method = methods.where((m) => m.id == methodId).firstOrNull;
    final now = ref.watch(clockProvider).now();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(
                      tab: _exchange
                          ? AddTab.exchange
                          : state.kind == TransactionKind.income
                          ? AddTab.income
                          : AddTab.expense,
                      onTab: (tab) {
                        setState(() => _exchange = tab == AddTab.exchange);
                        if (tab != AddTab.exchange) {
                          controller.setKind(
                            tab == AddTab.income
                                ? TransactionKind.income
                                : TransactionKind.expense,
                          );
                        }
                      },
                      onClose: () => context.pop(),
                    ),
                    if (_exchange) ...[
                      const SizedBox(height: 16),
                      Expanded(
                        child: ExchangeForm(startSelling: widget.sellDollars),
                      ),
                    ] else
                      ..._transactionBody(
                        context,
                        state,
                        controller,
                        method,
                        methods,
                        categories,
                        now,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _transactionBody(
    BuildContext context,
    AddTransactionState state,
    AddTransactionController controller,
    PaymentMethodRow? method,
    List<PaymentMethodRow> methods,
    List<CategoryRow> categories,
    DateTime now,
  ) {
    final c = context.colors;
    final isIncome = state.kind == TransactionKind.income;
    return [
      const SizedBox(height: 4),
      AmountDisplay(
        amount: state.amount,
        kind: state.kind,
        onCurrencyTap: () =>
            _showMessage(context, 'Only UZS is supported for now.'),
      ),
      const SizedBox(height: 12),
      _QuickChips(
        dayLabel: DateText.shortDay(state.day, now: now),
        method: method,
        note: state.note,
        showReceipt: !isIncome,
        hasReceipt: state.receipt != null,
        onDay: () => _pickDay(context, ref, state.day, now),
        onMethod: () => _pickMethod(context, ref, methods),
        onNote: () async {
          final note = await showNoteSheet(context, initial: state.note);
          if (note != null) controller.setNote(note);
        },
        onReceipt: () => _receipt(context, ref, state.receipt),
      ),
      const SizedBox(height: 12),
      _GroupHeader(
        title: isIncome ? 'Source' : 'Category',
        onEdit: () => context.push(Routes.categories),
      ),
      const SizedBox(height: 8),
      if (isIncome)
        IncomeCategoryGrid(
          categories: categories,
          selectedId: state.categoryId,
          onSelect: controller.selectCategory,
          onMore: () => _pickCategory(context, ref, categories),
        )
      else
        ExpenseCategoryGrid(
          categories: categories,
          selectedId: state.categoryId,
          onSelect: controller.selectCategory,
          onMore: () => _pickCategory(context, ref, categories),
        ),
      const Spacer(),
      const SizedBox(height: 12),
      NumberKeypad(onKey: controller.press, onClear: controller.clearAmount),
      const SizedBox(height: 12),
      PrimaryButton(
        label: _saveLabel(state),
        background: isIncome ? c.income : null,
        onPressed: state.canSave ? () => _save(context, ref) : null,
      ),
    ];
  }

  static String _saveLabel(AddTransactionState s) {
    final isIncome = s.kind == TransactionKind.income;
    final base = isIncome ? 'Save income' : 'Save expense';
    if (s.amount == 0) return base;
    if (s.categoryId == null) {
      return isIncome ? 'Choose a source' : 'Choose a category';
    }
    return isIncome
        ? '$base · ${MoneyFormat.signed(s.amount)}'
        : '$base · ${MoneyFormat.withCurrency(s.amount)}';
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final provider = addTransactionProvider(initialKind);
    final state = ref.read(provider);
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(transactionRepositoryProvider);
    final id = await ref.read(provider.notifier).save();
    if (id == null || !context.mounted) return;

    context.pop();
    final what = state.kind == TransactionKind.income ? 'Income' : 'Expense';
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '$what saved · ${MoneyFormat.withCurrency(state.amount)}',
        ),
        action: SnackBarAction(label: 'Undo', onPressed: () => repo.delete(id)),
      ),
    );
  }

  Future<void> _pickDay(
    BuildContext context,
    WidgetRef ref,
    DateTime current,
    DateTime now,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked != null) {
      ref.read(addTransactionProvider(initialKind).notifier).selectDay(picked);
    }
  }

  Future<void> _pickMethod(
    BuildContext context,
    WidgetRef ref,
    List<PaymentMethodRow> methods,
  ) async {
    final controller = ref.read(addTransactionProvider(initialKind).notifier);
    final picked = await showOptionSheet<int>(
      context,
      title: 'Payment method',
      selected: controller.effectivePaymentMethodId(),
      options: [
        for (final m in methods)
          SheetOption(
            value: m.id,
            label: m.name,
            leading: AppIcon(m.icon, size: 20),
          ),
      ],
      footer: Builder(
        builder: (sheetContext) => TextActionButton(
          label: 'Manage payment methods',
          icon: AppIcons.settings,
          onPressed: () {
            Navigator.pop(sheetContext);
            context.push(Routes.paymentMethods);
          },
        ),
      ),
    );
    if (picked != null) controller.selectPaymentMethod(picked);
  }

  Future<void> _pickCategory(
    BuildContext context,
    WidgetRef ref,
    List<CategoryRow> categories,
  ) async {
    final provider = addTransactionProvider(initialKind);
    final isIncome = ref.read(provider).kind == TransactionKind.income;
    final picked = await showOptionSheet<int>(
      context,
      title: isIncome ? 'All sources' : 'All categories',
      selected: ref.read(provider).categoryId,
      options: [
        for (final c in categories)
          SheetOption(
            value: c.id,
            label: c.name,
            leading: CategoryIconTile(icon: c.icon, color: c.color),
          ),
      ],
      footer: Builder(
        builder: (sheetContext) => TextActionButton(
          label: 'Manage categories',
          icon: AppIcons.settings,
          onPressed: () {
            Navigator.pop(sheetContext);
            context.push(Routes.categories);
          },
        ),
      ),
    );
    if (picked != null) ref.read(provider.notifier).selectCategory(picked);
  }

  /// Attaches a receipt photo, or offers to replace or remove it.
  Future<void> _receipt(
    BuildContext context,
    WidgetRef ref,
    String? current,
  ) async {
    final controller = ref.read(addTransactionProvider(initialKind).notifier);
    if (current != null) {
      final action = await showOptionSheet<String>(
        context,
        title: 'Receipt photo',
        options: const [
          SheetOption(value: 'replace', label: 'Replace photo'),
          SheetOption(value: 'remove', label: 'Remove photo'),
        ],
      );
      if (action == 'remove') controller.setReceipt(null);
      if (action != 'replace' || !context.mounted) return;
    }
    final name = await pickReceipt(context, ref);
    if (name != null) controller.setReceipt(name);
  }

  static void _showMessage(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.tab,
    required this.onTab,
    required this.onClose,
  });

  final AddTab tab;
  final ValueChanged<AddTab> onTab;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        CircleIconButton.raised(
          icon: AppIcons.close,
          semanticLabel: 'Close',
          onTap: onClose,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SegmentedTabs(
            options: [
              SegmentOption(
                AddTab.expense,
                'Expense',
                selectedColor: c.expense,
              ),
              SegmentOption(AddTab.income, 'Income', selectedColor: c.income),
              SegmentOption(
                AddTab.exchange,
                'Exchange',
                selectedColor: c.accent,
              ),
            ],
            selected: tab,
            onChanged: onTab,
          ),
        ),
      ],
    );
  }
}

class _QuickChips extends StatelessWidget {
  const _QuickChips({
    required this.dayLabel,
    required this.method,
    required this.note,
    required this.showReceipt,
    required this.hasReceipt,
    required this.onDay,
    required this.onMethod,
    required this.onNote,
    required this.onReceipt,
  });

  final String dayLabel;
  final PaymentMethodRow? method;
  final String? note;
  final bool showReceipt;
  final bool hasReceipt;
  final VoidCallback onDay;
  final VoidCallback onMethod;
  final VoidCallback onNote;
  final VoidCallback onReceipt;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ChipRow(
      padding: EdgeInsets.zero,
      children: [
        AppChip(label: dayLabel, leadingIcon: AppIcons.calendar, onTap: onDay),
        AppChip(
          label: method?.name ?? 'Payment',
          leadingIcon: method?.icon ?? AppIcons.card,
          trailingIcon: AppIcons.chevronDown,
          onTap: onMethod,
        ),
        AppChip(
          label: note == null ? 'Add note' : _short(note!),
          leadingIcon: AppIcons.pencil,
          onTap: onNote,
        ),
        if (showReceipt && hasReceipt)
          AppChip(
            label: 'Receipt',
            selected: true,
            leadingIcon: AppIcons.paperclip,
            semanticLabel: 'Receipt attached',
            onTap: onReceipt,
          )
        else if (showReceipt)
          Semantics(
            container: true,
            button: true,
            label: 'Attach receipt',
            excludeSemantics: true,
            child: Material(
              color: c.surface,
              shape: CircleBorder(side: BorderSide(color: c.divider)),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onReceipt,
                child: const SizedBox.square(
                  dimension: 40,
                  child: Center(child: AppIcon(AppIcons.paperclip, size: 16)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  static String _short(String s) =>
      s.length <= 18 ? s : '${s.substring(0, 17)}…';
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.title, required this.onEdit});

  final String title;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: AppText.overline13.copyWith(color: c.textSecondary),
          ),
        ),
        InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 32, minWidth: 44),
            child: Center(
              child: Text(
                'Edit',
                style: AppText.caption13.copyWith(color: c.textSecondary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
