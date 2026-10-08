import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/date_format.dart';
import '../../../core/format/money_format.dart';
import '../../../core/format/rate_input.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/option_sheet.dart';
import '../../../core/widgets/text_input_dialog.dart';
import '../../../data/db/app_database.dart';
import '../../../data/models/currency.dart';
import '../../../data/models/display_style.dart';
import '../../../data/models/exchange_details.dart';
import '../../../data/providers/data_providers.dart';
import '../../../router.dart';
import '../../add_transaction/ui/widgets/note_sheet.dart';
import '../../add_transaction/ui/widgets/number_keypad.dart';
import '../domain/exchange_math.dart';
import '../providers/exchange_controller.dart';

/// Body of the "Exchange" tab on the add screen: so'm ↔ dollars.
///
/// Exchanges only move money between balances. They are not income or
/// expenses.
class ExchangeForm extends ConsumerWidget {
  const ExchangeForm({super.key, this.startSelling = false, this.editing});

  /// Open in "sell dollars" mode instead of "buy dollars".
  final bool startSelling;

  /// A saved exchange to change. Null adds a new one.
  final ExchangeDetails? editing;

  ExchangeFormArgs get _args => (selling: startSelling, editing: editing);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final view = ref.watch(exchangeViewProvider(_args));
    final controller = ref.read(exchangeFormProvider(_args).notifier);
    final form = view.form;
    final now = ref.watch(clockProvider).now();
    final amounts = view.amounts;

    // The cards scroll; the keypad and the button stay at the bottom,
    // so they are always in reach, even on short phones or big text.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _MoneyCard(
                side: ExchangeSide.give,
                currency: view.giveCurrency,
                amount: amounts?.give ?? 0,
                active: form.typed == ExchangeSide.give,
                typed: form.digits,
                method: view.from,
                balanceText: _balanceText(view.from, view.fromBalance),
                // Red only once an amount is typed that is more than the
                // method holds.
                balanceShort:
                    view.from != null &&
                    (amounts?.give ?? 0) > 0 &&
                    amounts!.give + form.fee > view.fromBalance,
                onTap: () => controller.focus(ExchangeSide.give, amounts),
                onCurrency: controller.swap,
                onMethod: () => _pickMethod(
                  context,
                  view.fromMethods,
                  view.from,
                  controller.selectFromMethod,
                ),
              ),
              // The swap button sits on the gap between the two cards.
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: _MoneyCard(
                      side: ExchangeSide.get,
                      currency: view.getCurrency,
                      amount: amounts?.get ?? 0,
                      active: form.typed == ExchangeSide.get,
                      typed: form.digits,
                      method: view.to,
                      balanceText: view.to == null
                          ? null
                          : 'Balance ${_format(view.to!.currency, view.toBalance)}'
                                ' → ${_format(view.to!.currency, view.toBalance + (amounts?.get ?? 0))}',
                      onTap: () => controller.focus(ExchangeSide.get, amounts),
                      onCurrency: controller.swap,
                      onMethod: () => _pickMethod(
                        context,
                        view.toMethods,
                        view.to,
                        controller.selectToMethod,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 7 - 22,
                    left: 0,
                    right: 0,
                    child: Center(child: _SwapButton(onTap: controller.swap)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _RateCard(
                rate: view.rate,
                custom: view.rateIsCustom,
                manual: ref.watch(usdRateProvider)?.manual ?? false,
                onEdit: () => _editRate(context, ref, view.rate),
              ),
              const SizedBox(height: 14),
              ChipRow(
                padding: EdgeInsets.zero,
                children: [
                  AppChip(
                    label: DateText.shortDay(form.day, now: now),
                    leadingIcon: AppIcons.calendar,
                    onTap: () => _pickDay(context, ref, form.day, now),
                  ),
                  AppChip(
                    label: form.fee == 0
                        ? 'Add fee'
                        : 'Fee ${_format(view.giveCurrency, form.fee)}',
                    leadingIcon: AppIcons.plus,
                    selected: form.fee > 0,
                    onTap: () =>
                        _editFee(context, ref, view.giveCurrency, form.fee),
                  ),
                  AppChip(
                    label: form.note == null ? 'Add note' : _short(form.note!),
                    leadingIcon: AppIcons.pencil,
                    onTap: () async {
                      final note = await showNoteSheet(
                        context,
                        initial: form.note,
                      );
                      if (note != null) controller.setNote(note);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppIcon(AppIcons.info, size: 14, color: c.textTertiary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Exchanges move money between your so’m and dollar '
                        'balances. They don’t count as income or expenses.',
                        style: AppText.small12Regular.copyWith(
                          color: c.textTertiary,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        NumberKeypad(
          onKey: controller.press,
          onClear: controller.clearAmount,
          // Dollars can have cents; so'm cannot.
          decimal: form.currencyOf(form.typed) == Currency.usd,
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: editing != null && view.canSave
              ? 'Save changes'
              : _saveLabel(view),
          onPressed: view.canSave ? () => _save(context, ref, view) : null,
        ),
      ],
    );
  }

  static String _format(Currency currency, int minor) => switch (currency) {
    Currency.uzs => MoneyFormat.amount(minor),
    Currency.usd => MoneyFormat.dollars(minor),
  };

  /// Long notes are cut on the chip.
  static String _short(String s) =>
      s.length <= 18 ? s : '${s.substring(0, 17)}…';

  /// Amount on the button and the toast: "1 265 000 UZS" or "$100".
  static String _buttonAmount(Currency currency, int minor) =>
      switch (currency) {
        Currency.uzs => MoneyFormat.withCurrency(minor),
        Currency.usd => MoneyFormat.dollarsShort(minor),
      };

  static String? _balanceText(PaymentMethodRow? m, int balance) =>
      m == null ? null : 'Balance ${_format(m.currency, balance)}';

  static String _saveLabel(ExchangeView view) {
    if (view.rate == null) return 'Add a rate first';
    if (view.from == null || view.to == null) {
      return 'Add a dollar method first';
    }
    final a = view.amounts;
    if (a == null || a.give == 0 || a.get == 0) return 'Convert';
    return 'Convert ${_buttonAmount(view.giveCurrency, a.give)} → '
        '${_buttonAmount(view.getCurrency, a.get)}';
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    ExchangeView view,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(exchangeRepositoryProvider);
    final id = await ref.read(exchangeFormProvider(_args).notifier).save(view);
    if (id == null || !context.mounted) return;

    context.pop();
    final a = view.amounts!;
    if (editing != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Exchange updated')));
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Exchange saved · ${_buttonAmount(view.giveCurrency, a.give)} → '
          '${_buttonAmount(view.getCurrency, a.get)}',
        ),
        action: SnackBarAction(label: 'Undo', onPressed: () => repo.delete(id)),
      ),
    );
  }

  Future<void> _pickMethod(
    BuildContext context,
    List<PaymentMethodRow> methods,
    PaymentMethodRow? current,
    ValueChanged<int> onPicked,
  ) async {
    final picked = await showOptionSheet<int>(
      context,
      title: 'Payment method',
      selected: current?.id,
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
    if (picked != null) onPicked(picked);
  }

  Future<void> _editRate(
    BuildContext context,
    WidgetRef ref,
    double? current,
  ) async {
    final text = await showTextInputDialog(
      context,
      title: 'Exchange rate',
      initial: current == null ? '' : RateInput.plain(current),
      hint: '12650',
      suffix: 'UZS for 1 USD',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      validate: (t) =>
          RateInput.parse(t) == null ? 'Type a number, like 12650' : null,
    );
    final rate = text == null ? null : RateInput.parse(text);
    if (rate != null) {
      ref.read(exchangeFormProvider(_args).notifier).setRate(rate);
    }
  }

  Future<void> _editFee(
    BuildContext context,
    WidgetRef ref,
    Currency currency,
    int current,
  ) async {
    final dollars = currency == Currency.usd;
    final text = await showTextInputDialog(
      context,
      title: 'Fee',
      initial: current == 0
          ? ''
          : dollars
          ? RateInput.plain(current / 100)
          : '$current',
      hint: dollars ? '1.50' : '5000',
      suffix: currency.code,
      keyboardType: TextInputType.numberWithOptions(decimal: dollars),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(dollars ? r'[0-9.,]' : r'[0-9]'),
        ),
      ],
      validate: (t) => t.trim().isEmpty || RateInput.parse(t) != null
          ? null
          : 'Type a number',
    );
    if (text == null) return;
    final value = RateInput.parse(text) ?? 0;
    ref
        .read(exchangeFormProvider(_args).notifier)
        .setFee((value * currency.minorUnits).round());
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
      ref.read(exchangeFormProvider(_args).notifier).selectDay(picked);
    }
  }
}

/// "You give" or "You get" card: currency button, big amount, method
/// chip and balance. The card the keypad types into has a blue border.
class _MoneyCard extends StatelessWidget {
  const _MoneyCard({
    required this.side,
    required this.currency,
    required this.amount,
    required this.active,
    required this.typed,
    required this.method,
    required this.balanceText,
    required this.onTap,
    required this.onCurrency,
    required this.onMethod,
    this.balanceShort = false,
  });

  final ExchangeSide side;
  final Currency currency;

  /// In the smallest unit of [currency].
  final int amount;
  final bool active;

  /// What the keypad typed, like "100.5". Shown as it is on the active
  /// dollar card, so a "." or a trailing zero does not disappear.
  final String typed;
  final PaymentMethodRow? method;
  final String? balanceText;

  /// The "from" method has less money than this exchange takes.
  final bool balanceShort;
  final VoidCallback onTap;
  final VoidCallback onCurrency;
  final VoidCallback onMethod;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final title = side == ExchangeSide.give ? 'You give' : 'You get';
    final String text;
    if (currency == Currency.uzs) {
      text = MoneyFormat.amount(amount);
    } else {
      // Typed dollars show as typed; worked-out dollars show cents.
      text = active ? _typedDollars(typed) : MoneyFormat.dollars(amount);
    }
    final color = amount == 0
        ? c.textTertiary
        : active
        ? c.textPrimary
        : c.accent;
    final radius = BorderRadius.circular(AppRadius.card);

    return Semantics(
      container: true,
      label: '$title, ${currency.code}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: active
              ? null
              : AppShadows.card(Theme.of(context).brightness),
        ),
        child: Material(
          color: c.surface,
          borderRadius: radius,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: active ? c.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title.toUpperCase(),
                          style: AppText.overline13.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      ),
                      _CurrencyButton(currency: currency, onTap: onCurrency),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Semantics(
                    liveRegion: active,
                    label: '$title $text',
                    excludeSemantics: true,
                    child: Row(
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              text,
                              maxLines: 1,
                              style: AppText.amount40.copyWith(
                                color: color,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ),
                        if (active) ...[
                          const SizedBox(width: 4),
                          Container(
                            width: 2,
                            height: 36,
                            decoration: BoxDecoration(
                              color: c.accent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      AppChip(
                        label: method?.name ?? 'No method',
                        leadingIcon: method?.icon ?? AppIcons.card,
                        trailingIcon: AppIcons.chevronDown,
                        onTap: onMethod,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          balanceText ?? '',
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          style: AppText.small12Regular.copyWith(
                            color: balanceShort ? c.expense : c.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "100.5" → "$100.5", "1000." → "$1 000.", "" → "$0".
String _typedDollars(String typed) {
  if (typed.isEmpty) return r'$0';
  final [whole, ...rest] = typed.split('.');
  final grouped = MoneyFormat.amount(whole.isEmpty ? 0 : int.parse(whole));
  return rest.isEmpty ? '\$$grouped' : '\$$grouped.${rest.first}';
}

/// "S UZS so'm ⌄" pill. Tapping it swaps buy and sell.
class _CurrencyButton extends StatelessWidget {
  const _CurrencyButton({required this.currency, required this.onTap});

  final Currency currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (symbol, name) = switch (currency) {
      Currency.uzs => ('S', 'so’m'),
      Currency.usd => (r'$', 'dollar'),
    };
    return Semantics(
      container: true,
      button: true,
      label: 'Currency ${currency.code}. Tap to swap.',
      excludeSemantics: true,
      child: Material(
        color: c.surface,
        shape: StadiumBorder(side: BorderSide(color: c.divider)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 40,
            padding: const EdgeInsets.fromLTRB(6, 0, 10, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.accentSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    symbol,
                    style: AppText.small12Strong.copyWith(color: c.accent),
                  ),
                ),
                const SizedBox(width: 8),
                Text(currency.code, style: AppText.label14Strong),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: AppText.caption13Regular.copyWith(
                    color: c.textTertiary,
                  ),
                ),
                const SizedBox(width: 4),
                AppIcon(AppIcons.chevronDown, size: 14, color: c.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Round blue button between the cards. A ring in the page color makes
/// it look cut out of the cards.
class _SwapButton extends StatelessWidget {
  const _SwapButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      label: 'Swap direction',
      excludeSemantics: true,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: c.background, width: 4),
        ),
        child: Material(
          color: c.primary,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Center(
              child: AppIcon(AppIcons.sort, size: 18, color: c.onPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

class _RateCard extends StatelessWidget {
  const _RateCard({
    required this.rate,
    required this.custom,
    required this.manual,
    required this.onEdit,
  });

  final double? rate;
  final bool custom;
  final bool manual;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final note = switch ((rate, custom, manual)) {
      (null, _, _) => 'No rate yet. Tap Edit and type the rate you got.',
      (_, true, _) => 'Your rate for this exchange.',
      (_, _, true) =>
        'Your rate from Settings. Change it if your bank '
            'gave a different one.',
      _ => 'Today’s CBU rate. Change it if your bank gave a different one.',
    };
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(color: c.divider),
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card(Theme.of(context).brightness),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exchange rate',
                  style: AppText.small12Regular.copyWith(
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rate == null
                      ? '1 USD = — UZS'
                      : '1 USD = ${MoneyFormat.rate(rate!)} UZS',
                  style: AppText.body16Strong,
                ),
                const SizedBox(height: 2),
                Text(
                  note,
                  style: AppText.small12Regular.copyWith(color: c.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Semantics(
            container: true,
            button: true,
            label: 'Edit rate',
            excludeSemantics: true,
            child: Material(
              color: c.surface,
              shape: shape,
              child: InkWell(
                onTap: onEdit,
                customBorder: shape,
                child: SizedBox(
                  height: 40,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppIcon(AppIcons.pencil, size: 16),
                        const SizedBox(width: 6),
                        Text('Edit', style: AppText.label14),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
