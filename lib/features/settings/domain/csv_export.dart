import 'package:intl/intl.dart';

import '../../../data/models/transaction_details.dart';
import '../../../data/models/transaction_kind.dart';

/// Builds a CSV file (comma separated, UTF-8) with one row per
/// transaction, newest first. Amounts are plain numbers: negative for
/// expenses.
String buildTransactionsCsv(List<TransactionDetails> items) {
  final date = DateFormat('yyyy-MM-dd HH:mm');
  final rows = [
    [
      'Date',
      'Type',
      'Category',
      'Amount (UZS)',
      'Payment method',
      'Note',
      'Description',
    ],
    for (final t in items)
      [
        date.format(t.occurredAt),
        t.kind == TransactionKind.income ? 'Income' : 'Expense',
        t.category.name,
        '${t.signedAmount}',
        t.paymentMethod.name,
        t.transaction.note ?? '',
        t.transaction.description ?? '',
      ],
  ];
  return '${rows.map((r) => r.map(_cell).join(',')).join('\r\n')}\r\n';
}

/// Quotes a cell when it has a comma, quote or line break.
String _cell(String value) {
  if (!value.contains(RegExp(r'[",\r\n]'))) return value;
  return '"${value.replaceAll('"', '""')}"';
}
