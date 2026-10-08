import '../../../core/format/money_format.dart';
import '../../../core/icons/app_icons.dart';
import '../../dashboard/domain/dashboard_data.dart';
import 'dollar_stats.dart';

/// "The dollar rate rose 0.7% this month. Your $500 is now worth
/// 54 000 UZS more than you paid."
///
/// Null when a rate is missing or the rate did not move.
Insight? dollarRateInsight({
  required double? monthStartRate,
  required double? rate,
  required DollarStats stats,
}) {
  if (monthStartRate == null || rate == null || monthStartRate <= 0) {
    return null;
  }
  final change = (rate - monthStartRate) / monthStartRate * 100;
  if (change.abs() < 0.05) return null;

  final spans = <InsightSpan>[
    (text: 'The dollar rate ${change > 0 ? 'rose' : 'fell'} ', bold: false),
    (text: PercentFormat.value(change.abs(), decimals: 1), bold: true),
    (text: ' this month.', bold: false),
  ];
  final value = stats.valueChange(rate);
  if (value != null) {
    final dollars = MoneyFormat.dollarsShort(stats.boughtCents);
    spans.add((
      text: value == 0
          ? ' Your $dollars is worth what you paid.'
          : ' Your $dollars is now worth '
                '${MoneyFormat.withCurrency(value.abs())} '
                '${value > 0 ? 'more' : 'less'} than you paid.',
      bold: false,
    ));
  }
  return Insight(icon: AppIcons.exchange, spans: spans, accent: true);
}
