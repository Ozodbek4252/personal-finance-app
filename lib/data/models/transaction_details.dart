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

  /// Positive for income, negative for expense.
  int get signedAmount => transaction.amount * transaction.kind.sign;
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
  }) : assert(amount > 0, 'Amount must be positive.');

  final TransactionKind kind;

  /// Whole UZS, always positive.
  final int amount;
  final int categoryId;
  final int paymentMethodId;
  final DateTime occurredAt;
  final String? note;
  final String? description;
  final String? receiptPath;
}
