import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/currency.dart';
import '../../../data/models/transaction_details.dart';
import '../../../data/models/transaction_kind.dart';
import '../../../data/providers/data_providers.dart';
import '../../../data/receipts/receipt_store.dart';
import '../domain/amount_input.dart';

/// What the user has entered on the add screen so far.
class AddTransactionState {
  const AddTransactionState({
    required this.kind,
    required this.day,
    this.currency = Currency.uzs,
    this.digits = '',
    this.categoryIds = const {},
    this.paymentMethodId,
    this.note,
    this.receipt,
  });

  final TransactionKind kind;

  /// So'm, or dollars paid from (or received to) a dollar method.
  final Currency currency;

  /// Keypad input: whole so'm like "35000", or dollars like "34.12".
  final String digits;

  /// Chosen category for each kind, so switching tabs keeps both.
  final Map<TransactionKind, int> categoryIds;

  /// Null means "use the default payment method".
  final int? paymentMethodId;

  /// The chosen date (time of day is ignored).
  final DateTime day;
  final String? note;

  /// Stored file name of the receipt photo, if one was attached.
  final String? receipt;

  /// The typed amount: whole so'm, or cents for dollars.
  int get amount => currency == Currency.usd
      ? AmountInput.toCents(digits)
      : AmountInput.toAmount(digits);
  int? get categoryId => categoryIds[kind];
  bool get canSave => amount > 0 && categoryId != null;

  AddTransactionState copyWith({
    TransactionKind? kind,
    Currency? currency,
    String? digits,
    Map<TransactionKind, int>? categoryIds,
    int? Function()? paymentMethodId,
    DateTime? day,
    String? Function()? note,
    String? Function()? receipt,
  }) => AddTransactionState(
    kind: kind ?? this.kind,
    currency: currency ?? this.currency,
    digits: digits ?? this.digits,
    categoryIds: categoryIds ?? this.categoryIds,
    paymentMethodId: paymentMethodId == null
        ? this.paymentMethodId
        : paymentMethodId(),
    day: day ?? this.day,
    note: note == null ? this.note : note(),
    receipt: receipt == null ? this.receipt : receipt(),
  );
}

/// State of one open add screen. The family argument is the kind the
/// screen opened with; the user can switch kinds after that.
final addTransactionProvider = NotifierProvider.autoDispose
    .family<AddTransactionController, AddTransactionState, TransactionKind>(
      AddTransactionController.new,
    );

class AddTransactionController extends Notifier<AddTransactionState> {
  AddTransactionController(this._initialKind);

  final TransactionKind _initialKind;

  /// True while a save is running, so a double tap saves only once.
  bool _saving = false;

  /// True after the transaction was saved with its receipt.
  bool _receiptSaved = false;

  /// Copy of `state.receipt`, because `state` cannot be read in onDispose.
  String? _attachedReceipt;

  @override
  AddTransactionState build() {
    // A photo attached but never saved is not needed. The store is read
    // here because `ref` cannot be used while the provider is disposed.
    final store = ref.read(receiptStoreProvider);
    ref.onDispose(() {
      final receipt = _attachedReceipt;
      if (receipt != null && !_receiptSaved) store.delete(receipt);
    });
    return AddTransactionState(
      kind: _initialKind,
      day: ref.read(clockProvider).now(),
    );
  }

  void setKind(TransactionKind kind) => state = state.copyWith(kind: kind);

  void press(KeypadKey key) => state = state.copyWith(
    digits: state.currency == Currency.usd
        ? AmountInput.pressDecimal(state.digits, key)
        : AmountInput.press(state.digits, key),
  );

  /// So'm ↔ dollars. The amount starts over, and the payment method
  /// goes back to the default one of that currency.
  void setCurrency(Currency currency) {
    if (currency == state.currency) return;
    state = state.copyWith(
      currency: currency,
      digits: '',
      paymentMethodId: () => null,
    );
  }

  void clearAmount() => state = state.copyWith(digits: '');

  void selectCategory(int id) => state = state.copyWith(
    categoryIds: {...state.categoryIds, state.kind: id},
  );

  void selectPaymentMethod(int id) =>
      state = state.copyWith(paymentMethodId: () => id);

  void selectDay(DateTime day) => state = state.copyWith(day: day);

  /// Attaches a stored receipt photo; the old one (if any) is removed.
  void setReceipt(String? name) {
    final old = state.receipt;
    if (old != null && old != name) {
      ref.read(receiptStoreProvider).delete(old);
    }
    state = state.copyWith(receipt: () => name);
    _attachedReceipt = name;
  }

  void setNote(String? note) => state = state.copyWith(
    note: () => note == null || note.trim().isEmpty ? null : note.trim(),
  );

  /// The payment method that will be saved: the chosen one, else the
  /// default from Settings, else the first one in the list. Dollars use
  /// the first dollar method.
  int? effectivePaymentMethodId() {
    if (state.paymentMethodId != null) return state.paymentMethodId;
    if (state.currency == Currency.usd) {
      final dollars = ref.read(dollarMethodsProvider).value ?? const [];
      return dollars.firstOrNull?.id;
    }
    final methods = ref.read(paymentMethodsProvider).value ?? const [];
    final defaultId = ref.read(currentSettingsProvider).defaultPaymentMethodId;
    if (methods.any((m) => m.id == defaultId)) return defaultId;
    return methods.isEmpty ? null : methods.first.id;
  }

  /// Saves the transaction and returns its id, or null if something is
  /// missing.
  Future<int?> save() async {
    final s = state;
    final categoryId = s.categoryId;
    final methodId = effectivePaymentMethodId();
    if (_saving || !s.canSave || categoryId == null || methodId == null) {
      return null;
    }
    // Dollars are also saved in so'm at today's rate, for statistics.
    final dollars = s.currency == Currency.usd;
    final rate = ref.read(usdRateProvider)?.value;
    if (dollars && rate == null) return null;
    final som = dollars ? (s.amount * rate! / 100).round() : s.amount;
    if (som <= 0) return null;
    _saving = true;

    // Use the chosen day with the current time of day.
    final now = ref.read(clockProvider).now();
    final occurredAt = DateTime(
      s.day.year,
      s.day.month,
      s.day.day,
      now.hour,
      now.minute,
    );

    try {
      final id = await ref
          .read(transactionRepositoryProvider)
          .add(
            TransactionDraft(
              kind: s.kind,
              amount: som,
              usdAmount: dollars ? s.amount : null,
              categoryId: categoryId,
              paymentMethodId: methodId,
              occurredAt: occurredAt,
              note: s.note,
              receiptPath: s.receipt,
            ),
          );
      _receiptSaved = true;
      return id;
    } finally {
      _saving = false;
    }
  }
}
