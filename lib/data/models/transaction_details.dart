import '../db/app_database.dart';
import 'transaction_kind.dart';

/// A transaction together with its category and payment method.
/// Lists and the details screen use this.
class TransactionDetails {
  const TransactionDetails({
    required this.transaction,
    required this.category,
    required this.paymentMethod,
  });

  final TransactionRow transaction;
  final CategoryRow category;
  final PaymentMethodRow paymentMethod;

  int get id => transaction.id;
  TransactionKind get kind => transaction.kind;
  DateTime get occurredAt => transaction.occurredAt;

  /// Positive for income, negative for expense. In so'm, also for a
  /// dollar transaction (its so'm value at that day's rate).
  int get signedAmount => transaction.amount * transaction.kind.sign;

  /// Cents with the sign, for a dollar transaction; else null.
  int? get signedUsd => switch (transaction.usdAmount) {
    final cents? => cents * transaction.kind.sign,
    null => null,
  };
}

/// Data for a new transaction, or new values for an existing one.
class TransactionDraft {
  const TransactionDraft({
    required this.kind,
    required this.amount,
    required this.categoryId,
    required this.paymentMethodId,
    required this.occurredAt,
    this.note,
    this.description,
    this.receiptPath,
    this.usdAmount,
  }) : assert(amount > 0, 'Amount must be positive.'),
       assert(usdAmount == null || usdAmount > 0, 'Cents must be positive.');

  final TransactionKind kind;

  /// Whole UZS, always positive. For a dollar transaction, the so'm
  /// value of [usdAmount] at that day's rate.
  final int amount;

  /// Cents, for a transaction on a dollar method. Null for so'm.
  final int? usdAmount;
  final int categoryId;
  final int paymentMethodId;
  final DateTime occurredAt;
  final String? note;
  final String? description;
  final String? receiptPath;
}
