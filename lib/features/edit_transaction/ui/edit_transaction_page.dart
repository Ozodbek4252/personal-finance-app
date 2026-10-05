import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/amount_input_formatter.dart';
import '../../../core/format/date_format.dart';
import '../../../core/format/money_format.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/category_icon_tile.dart';
import '../../../core/widgets/option_sheet.dart';
import '../../../core/widgets/segmented_tabs.dart';
import '../../../data/db/app_database.dart';
import '../../../data/models/display_style.dart';
import '../../../data/models/transaction_details.dart';
import '../../../data/models/transaction_kind.dart';
import '../../../data/providers/data_providers.dart';
import '../../../data/receipts/receipt_store.dart';
import '../../receipts/receipt_widgets.dart';

/// Form to change every field of a transaction.
class EditTransactionPage extends ConsumerWidget {
  const EditTransactionPage({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Load the transaction once; the form then keeps its own copy.
    return switch (ref.watch(transactionProvider(id))) {
      AsyncData(value: final t?) => _EditForm(original: t),
      AsyncData() => const Scaffold(
        body: Center(child: Text('This transaction no longer exists.')),
      ),
      AsyncError(:final error) => Scaffold(body: Center(child: Text('$error'))),
      _ => const Scaffold(),
    };
  }
}

class _EditForm extends ConsumerStatefulWidget {
  const _EditForm({required this.original});

  final TransactionDetails original;

  @override
  ConsumerState<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends ConsumerState<_EditForm> {
  late final TransactionRow _row = widget.original.transaction;
  late TransactionKind _kind = _row.kind;
  late CategoryRow? _category = widget.original.category;
  late PaymentMethodRow _method = widget.original.paymentMethod;
  late DateTime _occurredAt = _row.occurredAt;
  late String? _receipt = _row.receiptPath;
  late final _amount = TextEditingController(
    text: MoneyFormat.amount(_row.amount),
  );
  late final _note = TextEditingController(text: _row.note ?? '');
  late final _description = TextEditingController(text: _row.description ?? '');
  bool _saving = false;

  /// Receipt files picked in this form. Ones that are not saved in the
  /// end are deleted when the form closes.
  final _newReceipts = <String>{};

  int get _amountValue => MoneyFormat.parseDigits(_amount.text);

  bool get _canSave => _amountValue > 0 && _category != null && !_saving;

  bool get _changed =>
      _kind != _row.kind ||
      _amountValue != _row.amount ||
      _category?.id != _row.categoryId ||
      _method.id != _row.paymentMethodId ||
      _occurredAt != _row.occurredAt ||
      _receipt != _row.receiptPath ||
      _note.text.trim() != (_row.note ?? '') ||
      _description.text.trim() != (_row.description ?? '');

  late final ReceiptStore _store;

  @override
  void initState() {
    super.initState();
    _store = ref.read(receiptStoreProvider);
    // Rebuild so the Save buttons follow what is typed.
    for (final c in [_amount, _note, _description]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    // Photos picked here but not saved in the end are not needed.
    // (`ref` must not be used in dispose, so use the saved store.)
    for (final name in _newReceipts) {
      if (name != _savedReceipt) _store.delete(name);
    }
    _amount.dispose();
    _note.dispose();
    _description.dispose();
    super.dispose();
  }

  /// The receipt name written by a successful save, if any.
  String? _savedReceipt;

  void _setKind(TransactionKind kind) {
    if (kind == _kind) return;
    setState(() {
      _kind = kind;
      // A category belongs to one kind, so pick it again.
      _category = kind == _row.kind ? widget.original.category : null;
    });
  }

  Future<void> _pickCategory() async {
    final categories = ref.read(categoriesProvider(_kind)).value ?? const [];
    final picked = await showOptionSheet<int>(
      context,
      title: _kind == TransactionKind.income ? 'Source' : 'Category',
      selected: _category?.id,
      options: [
        for (final c in categories)
          SheetOption(
            value: c.id,
            label: c.name,
            leading: CategoryIconTile(icon: c.icon, color: c.color),
          ),
      ],
    );
    if (picked != null) {
      setState(() => _category = categories.firstWhere((c) => c.id == picked));
    }
  }

  Future<void> _pickMethod() async {
    final methods = ref.read(paymentMethodsProvider).value ?? const [];
    final picked = await showOptionSheet<int>(
      context,
      title: 'Payment method',
      selected: _method.id,
      options: [
        for (final m in methods)
          SheetOption(
            value: m.id,
            label: m.name,
            leading: AppIcon(m.icon, size: 20),
          ),
      ],
    );
    if (picked != null) {
      setState(() => _method = methods.firstWhere((m) => m.id == picked));
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(ref.read(clockProvider).now().year + 1, 12, 31),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_occurredAt),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (!mounted) return;
    final t = time ?? TimeOfDay.fromDateTime(_occurredAt);
    setState(
      () => _occurredAt = DateTime(
        date.year,
        date.month,
        date.day,
        t.hour,
        t.minute,
      ),
    );
  }

  Future<void> _replaceReceipt() async {
    final name = await pickReceipt(context, ref);
    if (name == null || !mounted) return;
    setState(() {
      _newReceipts.add(name);
      _receipt = name;
    });
  }

  Future<void> _save() async {
    final category = _category;
    if (!_canSave || category == null) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    await ref
        .read(transactionRepositoryProvider)
        .update(
          _row.id,
          TransactionDraft(
            kind: _kind,
            amount: _amountValue,
            categoryId: category.id,
            paymentMethodId: _method.id,
            occurredAt: _occurredAt,
            note: _note.text,
            description: _description.text,
            receiptPath: _receipt,
          ),
        );
    _savedReceipt = _receipt;
    // The old photo is no longer used.
    final old = _row.receiptPath;
    if (old != null && old != _receipt) {
      await ref.read(receiptStoreProvider).delete(old);
    }
    if (!mounted) return;
    context.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Changes saved')));
  }

  /// Asks before throwing away unsaved changes.
  Future<void> _cancel() async {
    if (!_changed) {
      context.pop();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your edits to this transaction will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Discard',
              style: TextStyle(color: context.colors.expense),
            ),
          ),
        ],
      ),
    );
    if (discard == true && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final now = ref.watch(clockProvider).now();

    return PopScope(
      canPop: !_changed,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _Header(
                onCancel: _cancel,
                onSave: _canSave && _changed ? _save : null,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    SegmentedTabs(
                      options: [
                        SegmentOption(
                          TransactionKind.expense,
                          'Expense',
                          selectedColor: c.expense,
                        ),
                        SegmentOption(
                          TransactionKind.income,
                          'Income',
                          selectedColor: c.income,
                        ),
                      ],
                      selected: _kind,
                      onChanged: _setKind,
                    ),
                    const SizedBox(height: 14),
                    _AmountCard(controller: _amount),
                    const SizedBox(height: 14),
                    AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: Column(
                        children: [
                          _PickerRow(
                            leading: _category == null
                                ? _GreyTile(icon: AppIcons.box)
                                : CategoryIconTile(
                                    icon: _category!.icon,
                                    color: _category!.color,
                                  ),
                            label: _kind == TransactionKind.income
                                ? 'Source'
                                : 'Category',
                            value: _category?.name ?? 'Choose',
                            onTap: _pickCategory,
                          ),
                          _PickerRow(
                            leading: const _GreyTile(icon: AppIcons.calendar),
                            label: 'Date & time',
                            value: DateText.detail(_occurredAt),
                            onTap: _pickDateTime,
                            divider: true,
                          ),
                          _PickerRow(
                            leading: _GreyTile(icon: _method.icon),
                            label: 'Payment method',
                            value: _method.name,
                            onTap: _pickMethod,
                            divider: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _TextInput(
                            label: 'Note',
                            controller: _note,
                            maxLength: 60,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1, color: c.divider),
                          ),
                          _TextInput(
                            label: 'Description',
                            controller: _description,
                            maxLines: 3,
                            maxLength: 300,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ReceiptCard(
                      name: _receipt,
                      onAdd: _replaceReceipt,
                      onRemove: () => setState(() => _receipt = null),
                    ),
                    const SizedBox(height: 14),
                    PrimaryButton(
                      label: 'Save changes',
                      onPressed: _canSave && _changed ? _save : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _historyText(_row, now),
                      textAlign: TextAlign.center,
                      style: AppText.small12Regular.copyWith(
                        color: c.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "Created 30 Sep, 13:41 · Last edited just now".
  static String _historyText(TransactionRow row, DateTime now) {
    final created = 'Created ${DateText.dayMonthTime(row.createdAt)}';
    if (!row.updatedAt.isAfter(row.createdAt)) return created;
    final ago = now.difference(row.updatedAt);
    final edited = switch (ago.inMinutes) {
      < 1 => 'just now',
      < 60 => '${ago.inMinutes} min ago',
      _ => DateText.relativeDayTime(row.updatedAt, now: now),
    };
    return '$created · Last edited $edited';
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onCancel, required this.onSave});

  final VoidCallback onCancel;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: onCancel,
                  child: Text(
                    'Cancel',
                    style: AppText.body16.copyWith(color: c.textSecondary),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  'Edit transaction',
                  textAlign: TextAlign.center,
                  style: AppText.heading17,
                ),
              ),
            ),
            SizedBox(
              width: 100,
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onSave,
                  child: Text(
                    'Save',
                    style: AppText.body16Strong.copyWith(
                      color: onSave == null ? c.textTertiary : c.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amount',
            style: AppText.small12Regular.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [AmountInputFormatter()],
                  style: AppText.title28.copyWith(fontSize: 34),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: AppText.title28.copyWith(
                      fontSize: 34,
                      color: c.textTertiary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                MoneyFormat.currency,
                style: AppText.body17.copyWith(color: c.textTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Grey rounded square with an icon, for the date and payment rows.
class _GreyTile extends StatelessWidget {
  const _GreyTile({required this.icon});

  final AppIconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
      ),
      child: AppIcon(icon, size: 18, color: c.textSecondary),
    );
  }
}

/// Row that shows a value and opens a picker when tapped.
class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.leading,
    required this.label,
    required this.value,
    required this.onTap,
    this.divider = false,
  });

  final Widget leading;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      label: '$label: $value',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: divider ? Border(top: BorderSide(color: c.divider)) : null,
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppText.small12Regular.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(value, style: AppText.body15),
                  ],
                ),
              ),
              AppIcon(AppIcons.chevronRight, size: 18, color: c.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Borderless text field with a small "Label · optional" title.
class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.maxLength,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: label),
              TextSpan(
                text: ' · optional',
                style: AppText.small12Regular.copyWith(color: c.textTertiary),
              ),
            ],
          ),
          style: AppText.small12.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          minLines: 1,
          maxLength: maxLength,
          textCapitalization: TextCapitalization.sentences,
          style: AppText.body15Regular.copyWith(height: 1.45),
          decoration: InputDecoration(
            isCollapsed: true,
            border: InputBorder.none,
            // The limit is enforced quietly; no counter under the field.
            counterText: '',
            hintText: 'Add ${label.toLowerCase()}',
            hintStyle: AppText.body15Regular.copyWith(color: c.textTertiary),
          ),
        ),
      ],
    );
  }
}

class _ReceiptCard extends ConsumerWidget {
  const _ReceiptCard({
    required this.name,
    required this.onAdd,
    required this.onRemove,
  });

  final String? name;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final name = this.name;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Receipt'),
                TextSpan(
                  text: ' · optional',
                  style: AppText.small12Regular.copyWith(color: c.textTertiary),
                ),
              ],
            ),
            style: AppText.small12.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: 10),
          if (name == null)
            SecondaryButton(
              label: 'Add photo',
              icon: AppIcons.paperclip,
              onPressed: onAdd,
            )
          else
            Row(
              children: [
                GestureDetector(
                  onTap: () => showReceiptViewer(context, ref, name),
                  child: ReceiptThumb(name: name, width: 48, height: 60),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Receipt photo',
                    style: AppText.body15,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _SmallOutlined(onTap: onAdd, child: const Text('Replace')),
                const SizedBox(width: 8),
                _SmallOutlined(
                  onTap: onRemove,
                  semanticLabel: 'Remove receipt',
                  child: AppIcon(
                    AppIcons.close,
                    size: 16,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// 40 px outlined button used in the receipt row.
class _SmallOutlined extends StatelessWidget {
  const _SmallOutlined({
    required this.onTap,
    required this.child,
    this.semanticLabel,
  });

  final VoidCallback onTap;
  final Widget child;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(color: c.divider),
    );
    return Semantics(
      container: true,
      button: true,
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: Material(
        color: c.surface,
        shape: shape,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                widthFactor: 1,
                child: DefaultTextStyle(
                  style: AppText.label14.copyWith(color: c.textPrimary),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
