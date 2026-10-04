import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/transaction_details.dart';
import '../../../data/models/transaction_kind.dart';
import '../../../data/providers/data_providers.dart';
import '../domain/amount_input.dart';

/// What the user has entered on the add screen so far.
class AddTransactionState {
  const AddTransactionState({
    required this.kind,
    required this.day,
    this.digits = '',
    this.categoryIds = const {},
    this.paymentMethodId,
    this.note,
  });

  final TransactionKind kind;

  /// Keypad input, like "35000".
  final String digits;

  /// Chosen category for each kind, so switching tabs keeps both.
  final Map<TransactionKind, int> categoryIds;

  /// Null means "use the default payment method".
  final int? paymentMethodId;

  /// The chosen date (time of day is ignored).
  final DateTime day;
  final String? note;

  int get amount => AmountInput.toAmount(digits);
  int? get categoryId => categoryIds[kind];
  bool get canSave => amount > 0 && categoryId != null;

  AddTransactionState copyWith({
    TransactionKind? kind,
    String? digits,
    Map<TransactionKind, int>? categoryIds,
    int? paymentMethodId,
    DateTime? day,
    String? Function()? note,
  }) => AddTransactionState(
    kind: kind ?? this.kind,
    digits: digits ?? this.digits,
    categoryIds: categoryIds ?? this.categoryIds,
    paymentMethodId: paymentMethodId ?? this.paymentMethodId,
    day: day ?? this.day,
    note: note == null ? this.note : note(),
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

  @override
  AddTransactionState build() => AddTransactionState(
    kind: _initialKind,
    day: ref.read(clockProvider).now(),
  );

  void setKind(TransactionKind kind) => state = state.copyWith(kind: kind);

  void press(KeypadKey key) =>
      state = state.copyWith(digits: AmountInput.press(state.digits, key));

  void clearAmount() => state = state.copyWith(digits: '');

  void selectCategory(int id) => state = state.copyWith(
    categoryIds: {...state.categoryIds, state.kind: id},
  );

  void selectPaymentMethod(int id) =>
      state = state.copyWith(paymentMethodId: id);

  void selectDay(DateTime day) => state = state.copyWith(day: day);

  void setNote(String? note) => state = state.copyWith(
    note: () => note == null || note.trim().isEmpty ? null : note.trim(),
  );

  /// The payment method that will be saved: the chosen one, else the
  /// default from Settings, else the first one in the list.
  int? effectivePaymentMethodId() {
    if (state.paymentMethodId != null) return state.paymentMethodId;
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
      return await ref
          .read(transactionRepositoryProvider)
          .add(
            TransactionDraft(
              kind: s.kind,
              amount: s.amount,
              categoryId: categoryId,
              paymentMethodId: methodId,
              occurredAt: occurredAt,
              note: s.note,
            ),
          );
    } finally {
      _saving = false;
    }
  }
}
