import '../db/app_database.dart';
import 'currency.dart';

/// An exchange together with the two payment methods it moves money
/// between. Lists and the details screen use this.
class ExchangeDetails {
  const ExchangeDetails({
    required this.exchange,
    required this.from,
    required this.to,
  });

  final ExchangeRow exchange;
  final PaymentMethodRow from;
  final PaymentMethodRow to;

  int get id => exchange.id;
  DateTime get occurredAt => exchange.occurredAt;
  Currency get fromCurrency => from.currency;
  Currency get toCurrency => to.currency;
}

/// Data for a new exchange, or new values for an existing one.
class ExchangeDraft {
  const ExchangeDraft({
    required this.fromMethodId,
    required this.fromAmount,
    required this.toMethodId,
    required this.toAmount,
    required this.rate,
    required this.occurredAt,
    this.fee = 0,
    this.note,
  }) : assert(fromAmount > 0 && toAmount > 0, 'Amounts must be positive.'),
       assert(fee >= 0, 'Fee cannot be negative.'),
       assert(rate > 0, 'Rate must be positive.'),
       assert(fromMethodId != toMethodId, 'Methods must be different.');

  final int fromMethodId;

  /// In the smallest unit of the "from" method's currency.
  final int fromAmount;
  final int toMethodId;

  /// In the smallest unit of the "to" method's currency.
  final int toAmount;

  /// UZS for 1 USD.
  final double rate;

  /// Extra cost in the smallest unit of the "from" currency.
  final int fee;
  final DateTime occurredAt;
  final String? note;
}
