import '../../../data/models/currency.dart';
import '../../../data/models/exchange_details.dart';
import '../../../data/models/transaction_details.dart';

/// One row in the transaction list: an expense or income, or an
/// exchange between so'm and dollars.
sealed class ListEntry {
  const ListEntry();

  DateTime get occurredAt;

  /// Id in its own table. A transaction and an exchange can share one.
  int get id;

  /// So'm that moved, for the "Largest amount" order.
  int get somAmount;

  /// Effect on the so'm In/Out/Net totals. Exchanges are not income or
  /// expenses, so they count as 0.
  int get signedSom;
}

final class TransactionEntry extends ListEntry {
  const TransactionEntry(this.item);

  final TransactionDetails item;

  @override
  DateTime get occurredAt => item.occurredAt;
  @override
  int get id => item.id;
  @override
  int get somAmount => item.transaction.amount;
  @override
  int get signedSom => item.signedAmount;
}

final class ExchangeEntry extends ListEntry {
  const ExchangeEntry(this.item);

  final ExchangeDetails item;

  @override
  DateTime get occurredAt => item.occurredAt;
  @override
  int get id => item.id;
  @override
  int get somAmount => item.fromCurrency == Currency.uzs
      ? item.exchange.fromAmount
      : item.exchange.toAmount;
  @override
  int get signedSom => 0;
}
