import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/amount_input_formatter.dart';
import '../../../core/format/money_format.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/time/clock.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/option_sheet.dart';
import '../../../core/widgets/text_input_dialog.dart';
import '../../../data/models/currency.dart';
import '../../../data/db/app_database.dart';
import '../../../data/models/display_style.dart';
import '../../../data/providers/data_providers.dart';

/// Default method, the list of methods, and a field to add a new one.
class PaymentMethodsPage extends ConsumerStatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  ConsumerState<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends ConsumerState<PaymentMethodsPage> {
  final _newName = TextEditingController();
  final _newNameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _newName.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _newName.dispose();
    _newNameFocus.dispose();
    super.dispose();
  }

  List<PaymentMethodRow> get _methods =>
      ref.read(paymentMethodsProvider).value ?? const [];

  /// Error for a method name, or null when it is fine.
  String? _nameError(String text, {int? exceptId}) {
    final name = text.trim().toLowerCase();
    if (name.isEmpty) return 'Enter a name';
    final taken = _methods.any(
      (m) => m.name.toLowerCase() == name && m.id != exceptId,
    );
    return taken ? 'You already have this method' : null;
  }

  Future<void> _add() async {
    if (_nameError(_newName.text) != null) return;
    await ref.read(paymentMethodRepositoryProvider).addCustom(_newName.text);
    _newName.clear();
    _newNameFocus.unfocus();
  }

  Future<void> _changeDefault(int? currentId) async {
    final picked = await showOptionSheet<int>(
      context,
      title: 'Default method',
      selected: currentId,
      options: [
        for (final m in _methods)
          SheetOption(
            value: m.id,
            label: m.name,
            leading: AppIcon(m.icon, size: 20),
          ),
      ],
    );
    if (picked != null) {
      await ref
          .read(settingsRepositoryProvider)
          .setDefaultPaymentMethod(picked);
    }
  }

  Future<void> _openMethod(PaymentMethodRow m, bool isDefault) async {
    final balance = ref.read(balancesProvider(Currency.uzs)).value?[m.id] ?? 0;
    final canRemove = !isDefault && _methods.length > 1;
    final action = await showOptionSheet<String>(
      context,
      title: '${m.name} · ${MoneyFormat.withCurrency(balance)}',
      options: [
        if (!isDefault)
          const SheetOption(
            value: 'default',
            label: 'Make default',
            leading: AppIcon(AppIcons.check, size: 20),
          ),
        const SheetOption(
          value: 'rename',
          label: 'Rename',
          leading: AppIcon(AppIcons.pencil, size: 20),
        ),
        SheetOption(
          value: 'opening',
          label: 'Starting balance',
          subtitle: MoneyFormat.withCurrency(m.openingBalance),
          leading: const AppIcon(AppIcons.wallet, size: 20),
        ),
        if (canRemove)
          const SheetOption(
            value: 'remove',
            label: 'Remove',
            leading: AppIcon(AppIcons.trash, size: 20),
          ),
      ],
    );
    if (!mounted || action == null) return;
    final repo = ref.read(paymentMethodRepositoryProvider);
    switch (action) {
      case 'default':
        await ref
            .read(settingsRepositoryProvider)
            .setDefaultPaymentMethod(m.id);
      case 'rename':
        final name = await showTextInputDialog(
          context,
          title: 'Rename method',
          initial: m.name,
          validate: (t) => _nameError(t, exceptId: m.id),
        );
        if (name != null) await repo.rename(m.id, name);
      case 'opening':
        final text = await showTextInputDialog(
          context,
          title: 'Starting balance',
          initial: m.openingBalance == 0
              ? ''
              : MoneyFormat.amount(m.openingBalance),
          hint: '0',
          suffix: MoneyFormat.currency,
          keyboardType: TextInputType.number,
          inputFormatters: const [AmountInputFormatter()],
        );
        if (text != null) {
          await repo.setOpeningBalance(m.id, MoneyFormat.parseDigits(text));
        }
      case 'remove':
        await repo.archive(m.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final methods = ref.watch(paymentMethodsProvider).value ?? const [];
    final defaultId = ref.watch(currentSettingsProvider).defaultPaymentMethodId;
    final month = monthStart(ref.watch(clockProvider).now());
    final counts = <int, int>{};
    for (final t in ref.watch(monthTransactionsProvider(month)).value ?? []) {
      counts.update(t.paymentMethod.id, (n) => n + 1, ifAbsent: () => 1);
    }
    final defaultMethod = methods.where((m) => m.id == defaultId).firstOrNull;
    final addError = _newName.text.trim().isEmpty
        ? null
        : _nameError(_newName.text);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onBack: () => context.pop(),
              onAdd: () => _newNameFocus.requestFocus(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                children: [
                  AppCard(
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: c.savingsSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: AppIcon(AppIcons.check, color: c.savings),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Default for new transactions',
                                style: AppText.small12Regular.copyWith(
                                  color: c.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                defaultMethod?.name ?? 'Not set',
                                style: AppText.body16Strong,
                              ),
                            ],
                          ),
                        ),
                        _OutlinedSmall(
                          label: 'Change',
                          onTap: () => _changeDefault(defaultId),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                    child: Text(
                      'YOUR METHODS',
                      style: AppText.overline13.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Column(
                      children: [
                        for (final (i, m) in methods.indexed)
                          _MethodRow(
                            method: m,
                            count: counts[m.id] ?? 0,
                            isDefault: m.id == defaultId,
                            showDivider: i > 0,
                            onTap: () => _openMethod(m, m.id == defaultId),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'ADD CUSTOM METHOD',
                          style: AppText.overline13.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _newName,
                                focusNode: _newNameFocus,
                                maxLength: 40,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                onSubmitted: (_) => _add(),
                                style: AppText.body15Regular,
                                decoration: InputDecoration(
                                  counterText: '',
                                  hintText: 'e.g. Payme, Kapitalbank card',
                                  hintStyle: AppText.body15Regular.copyWith(
                                    color: c.textTertiary,
                                  ),
                                  errorText: addError,
                                  filled: true,
                                  fillColor: c.background,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                  border: _border(c.divider),
                                  enabledBorder: _border(c.divider),
                                  focusedBorder: _border(c.textPrimary),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _AddButton(
                              onTap:
                                  _newName.text.trim().isEmpty ||
                                      addError != null
                                  ? null
                                  : _add,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.onAdd});

  final VoidCallback onBack;
  final VoidCallback onAdd;

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
                  'Payment methods',
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
                  semanticLabel: 'Add payment method',
                  onTap: onAdd,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodRow extends StatelessWidget {
  const _MethodRow({
    required this.method,
    required this.count,
    required this.isDefault,
    required this.showDivider,
    required this.onTap,
  });

  final PaymentMethodRow method;
  final int count;
  final bool isDefault;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final badge = isDefault
        ? ('Default', c.savings, c.savingsSoft)
        : method.isCustom
        ? ('Custom', c.textSecondary, c.surfaceMuted)
        : null;
    return Semantics(
      container: true,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: showDivider
                ? Border(top: BorderSide(color: c.divider))
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AppIcon(method.icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(method.name, style: AppText.body15),
                    const SizedBox(height: 2),
                    Text(
                      count == 0
                          ? 'None this month'
                          : '$count ${count == 1 ? 'transaction' : 'transactions'} '
                                'this month',
                      style: AppText.small12Regular.copyWith(
                        color: c.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              if (badge case (final text, final fg, final bg)) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    text,
                    style: AppText.tiny11Strong.copyWith(color: fg),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              AppIcon(AppIcons.chevronRight, size: 18, color: c.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlinedSmall extends StatelessWidget {
  const _OutlinedSmall({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

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
      child: Material(
        color: c.surface,
        shape: shape,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: SizedBox(
            height: 40,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                widthFactor: 1,
                child: Text(label, style: AppText.label14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onTap != null;
    final radius = BorderRadius.circular(AppRadius.small);
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      child: Material(
        color: enabled ? c.primary : c.surfaceMuted,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Center(
                widthFactor: 1,
                child: Text(
                  'Add',
                  style: AppText.body15Strong.copyWith(
                    color: enabled ? c.onPrimary : c.textTertiary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
