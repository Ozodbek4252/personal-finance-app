import 'package:intl/intl.dart';

import '../../../data/models/currency.dart';
import '../../../data/models/exchange_details.dart';
import '../../../data/models/transaction_details.dart';
import '../../../data/models/transaction_kind.dart';

/// Builds a CSV file (comma separated, UTF-8) with one row per
/// transaction or exchange, newest first. Amounts are plain numbers:
/// negative when money goes out.
///
/// An exchange fills both amount columns, like "−1265000" and "100.00",
/// and its payment method is "Humo → Cash (USD)".
String buildTransactionsCsv(
  List<TransactionDetails> items, {
  List<ExchangeDetails> exchanges = const [],
}) {
  final date = DateFormat('yyyy-MM-dd HH:mm');
  final rows = <(DateTime, List<String>)>[
    for (final t in items)
      (
        t.occurredAt,
        [
          date.format(t.occurredAt),
          t.kind == TransactionKind.income ? 'Income' : 'Expense',
          t.category.name,
          '${t.signedAmount}',
          '',
          t.paymentMethod.name,
          t.transaction.note ?? '',
          t.transaction.description ?? '',
        ],
      ),
    for (final e in exchanges)
      (
        e.occurredAt,
        [
          date.format(e.occurredAt),
          'Exchange',
          '',
          _plain(_change(e, Currency.uzs), Currency.uzs),
          _plain(_change(e, Currency.usd), Currency.usd),
          '${e.from.name} → ${e.to.name}',
          e.exchange.note ?? '',
          'Rate ${e.exchange.rate}',
        ],
      ),
  ]..sort((a, b) => b.$1.compareTo(a.$1));
  final table = [
    [
      'Date',
      'Type',
      'Category',
      'Amount (UZS)',
      'Amount (USD)',
      'Payment method',
      'Note',
      'Description',
    ],
    for (final (_, row) in rows) row,
  ];
  return '${table.map((r) => r.map(_cell).join(',')).join('\r\n')}\r\n';
}

/// How much an exchange changed the [currency] balance: the "from" side
/// (with its fee) goes out, the "to" side comes in.
int _change(ExchangeDetails e, Currency currency) {
  var change = 0;
  if (e.fromCurrency == currency) {
    change -= e.exchange.fromAmount + e.exchange.fee;
  }
  if (e.toCurrency == currency) change += e.exchange.toAmount;
  return change;
}

/// Smallest units as a plain number: so'm stay whole, cents get two
/// decimals (−1250 → "-12.50").
String _plain(int value, Currency currency) {
  if (currency.minorUnits == 1) return '$value';
  final abs = value.abs();
  final cents = (abs % 100).toString().padLeft(2, '0');
  return '${value < 0 ? '-' : ''}${abs ~/ 100}.$cents';
}

/// Quotes a cell when it has a comma, quote or line break.
String _cell(String value) {
  if (!value.contains(RegExp(r'[",\r\n]'))) return value;
  return '"${value.replaceAll('"', '""')}"';
}
