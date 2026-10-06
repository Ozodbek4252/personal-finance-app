import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../data/models/currency.dart';
import '../../../data/models/exchange_details.dart';
import '../../../data/providers/data_providers.dart';
import '../../add_transaction/domain/amount_input.dart';
import '../domain/exchange_math.dart';

/// What the user has entered on the Exchange screen so far.
class ExchangeFormState {
  const ExchangeFormState({
    required this.selling,
    required this.day,
    this.typed = ExchangeSide.give,
    this.digits = '',
    this.fromMethodId,
    this.toMethodId,
    this.rate,
    this.fee = 0,
    this.note,
  });

  /// False: so'm → dollars (buy). True: dollars → so'm (sell).
  final bool selling;

  /// The card the keypad types into. The other card is worked out.
  final ExchangeSide typed;

  /// Keypad input in whole so'm or whole dollars, like "1265000".
  final String digits;

  /// Null means "use the default method" (see [ExchangeView]).
  final int? fromMethodId;
  final int? toMethodId;

  /// A rate typed for this exchange only. Null means today's rate.
  final double? rate;

  /// Extra cost in the smallest unit of the "from" currency.
  final int fee;

  /// The chosen date (time of day is ignored).
  final DateTime day;
  final String? note;

  int get whole => AmountInput.toAmount(digits);

  Currency currencyOf(ExchangeSide side) =>
      ExchangeMath.currencyOf(side, selling: selling);

  ExchangeFormState copyWith({
    bool? selling,
    ExchangeSide? typed,
    String? digits,
    int? Function()? fromMethodId,
    int? Function()? toMethodId,
    double? rate,
    int? fee,
    DateTime? day,
    String? Function()? note,
  }) => ExchangeFormState(
    selling: selling ?? this.selling,
    typed: typed ?? this.typed,
    digits: digits ?? this.digits,
    fromMethodId: fromMethodId == null ? this.fromMethodId : fromMethodId(),
    toMethodId: toMethodId == null ? this.toMethodId : toMethodId(),
    rate: rate ?? this.rate,
    fee: fee ?? this.fee,
    day: day ?? this.day,
    note: note == null ? this.note : note(),
  );
}

/// State of the open Exchange screen. The family argument is true when
/// it opens to sell dollars.
final exchangeFormProvider = NotifierProvider.autoDispose
    .family<ExchangeController, ExchangeFormState, bool>(
      ExchangeController.new,
    );

class ExchangeController extends Notifier<ExchangeFormState> {
  ExchangeController(this._startSelling);

  final bool _startSelling;

  /// True while a save is running, so a double tap saves only once.
  bool _saving = false;

  @override
  ExchangeFormState build() => ExchangeFormState(
    selling: _startSelling,
    day: ref.read(clockProvider).now(),
  );

  void press(KeypadKey key) =>
      state = state.copyWith(digits: AmountInput.press(state.digits, key));

  void clearAmount() => state = state.copyWith(digits: '');

  /// Makes the keypad type into [side]. The amount shown on that card
  /// stays, so the user can go on from it.
  void focus(ExchangeSide side, ExchangeAmounts? shown) {
    if (side == state.typed) return;
    final currency = state.currencyOf(side);
    final minor = switch (side) {
      ExchangeSide.give => shown?.give ?? 0,
      ExchangeSide.get => shown?.get ?? 0,
    };
    final whole = (minor / currency.minorUnits).round();
    state = state.copyWith(typed: side, digits: whole == 0 ? '' : '$whole');
  }

  /// Buy ↔ sell. The typed amount stays with its currency, and the two
  /// methods change places.
  void swap() {
    final s = state;
    state = s.copyWith(
      selling: !s.selling,
      typed: s.typed == ExchangeSide.give
          ? ExchangeSide.get
          : ExchangeSide.give,
      fromMethodId: () => s.toMethodId,
      toMethodId: () => s.fromMethodId,
      // A fee was in the old "from" currency, so it no longer fits.
      fee: 0,
    );
  }

  void selectFromMethod(int id) =>
      state = state.copyWith(fromMethodId: () => id);
  void selectToMethod(int id) => state = state.copyWith(toMethodId: () => id);
  void setRate(double rate) => state = state.copyWith(rate: rate);
  void setFee(int fee) => state = state.copyWith(fee: fee < 0 ? 0 : fee);
  void selectDay(DateTime day) => state = state.copyWith(day: day);

  void setNote(String? note) => state = state.copyWith(
    note: () => note == null || note.trim().isEmpty ? null : note.trim(),
  );

  /// Saves the exchange and returns its id, or null if something is
  /// missing.
  Future<int?> save(ExchangeView view) async {
    final amounts = view.amounts;
    final from = view.from;
    final to = view.to;
    final rate = view.rate;
    if (_saving || !view.canSave) return null;
    if (amounts == null || from == null || to == null || rate == null) {
      return null;
    }
    _saving = true;

    // Use the chosen day with the current time of day.
    final now = ref.read(clockProvider).now();
    final day = state.day;
    try {
      return await ref
          .read(exchangeRepositoryProvider)
          .add(
            ExchangeDraft(
              fromMethodId: from.id,
              fromAmount: amounts.give,
              toMethodId: to.id,
              toAmount: amounts.get,
              rate: rate,
              fee: state.fee,
              occurredAt: DateTime(
                day.year,
                day.month,
                day.day,
                now.hour,
                now.minute,
              ),
              note: state.note,
            ),
          );
    } finally {
      _saving = false;
    }
  }
}

/// Everything the Exchange screen shows, worked out from the form,
/// today's rate, the methods and their balances.
class ExchangeView {
  const ExchangeView({
    required this.form,
    required this.rate,
    required this.rateIsCustom,
    required this.amounts,
    required this.from,
    required this.to,
    required this.fromMethods,
    required this.toMethods,
    required this.fromBalance,
    required this.toBalance,
  });

  final ExchangeFormState form;

  /// The rate used, or null when there is none yet.
  final double? rate;

  /// True when the user typed a rate for this exchange.
  final bool rateIsCustom;

  /// Null while there is no rate.
  final ExchangeAmounts? amounts;
  final PaymentMethodRow? from;
  final PaymentMethodRow? to;

  /// Methods the user can pick on each card.
  final List<PaymentMethodRow> fromMethods;
  final List<PaymentMethodRow> toMethods;

  /// Current balances, in the smallest unit of each method's currency.
  final int fromBalance;
  final int toBalance;

  Currency get giveCurrency => form.currencyOf(ExchangeSide.give);
  Currency get getCurrency => form.currencyOf(ExchangeSide.get);

  bool get canSave =>
      amounts != null &&
      amounts!.give > 0 &&
      amounts!.get > 0 &&
      from != null &&
      to != null;
}

final exchangeViewProvider = Provider.autoDispose.family<ExchangeView, bool>((
  ref,
  startSelling,
) {
  final form = ref.watch(exchangeFormProvider(startSelling));
  final todayRate = ref.watch(usdRateProvider)?.value;
  final rate = form.rate ?? todayRate;
  final som = ref.watch(paymentMethodsProvider).value ?? const [];
  final usd = ref.watch(dollarMethodsProvider).value ?? const [];
  final somBalances =
      ref.watch(balancesProvider(Currency.uzs)).value ?? const {};
  final usdBalances =
      ref.watch(balancesProvider(Currency.usd)).value ?? const {};
  final defaultSomId = ref
      .watch(currentSettingsProvider)
      .defaultPaymentMethodId;

  PaymentMethodRow? pick(
    List<PaymentMethodRow> list,
    int? chosen,
    int? fallback,
  ) =>
      list.where((m) => m.id == chosen).firstOrNull ??
      list.where((m) => m.id == fallback).firstOrNull ??
      list.firstOrNull;

  final fromList = form.selling ? usd : som;
  final toList = form.selling ? som : usd;
  final from = pick(
    fromList,
    form.fromMethodId,
    form.selling ? null : defaultSomId,
  );
  final to = pick(toList, form.toMethodId, form.selling ? defaultSomId : null);
  int balanceOf(PaymentMethodRow? m) => m == null
      ? 0
      : ((m.currency == Currency.uzs ? somBalances : usdBalances)[m.id] ?? 0);

  return ExchangeView(
    form: form,
    rate: rate,
    rateIsCustom: form.rate != null,
    amounts: rate == null
        ? null
        : ExchangeMath.amounts(
            selling: form.selling,
            typed: form.typed,
            whole: form.whole,
            rate: rate,
          ),
    from: from,
    to: to,
    fromMethods: fromList,
    toMethods: toList,
    fromBalance: balanceOf(from),
    toBalance: balanceOf(to),
  );
});
