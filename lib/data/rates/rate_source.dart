import 'dart:convert';
import 'dart:io';

/// An official rate for one day.
class OfficialRate {
  const OfficialRate({required this.day, required this.rate});

  /// The day the rate is for (local midnight).
  final DateTime day;

  /// UZS for 1 USD.
  final double rate;
}

/// Thrown when the rate cannot be loaded (no internet, server down,
/// unexpected answer).
class RateUnavailableException implements Exception {
  const RateUnavailableException(this.reason);
  final String reason;

  @override
  String toString() => 'RateUnavailableException: $reason';
}

/// Where official USD rates come from. Tests use a fake.
abstract interface class RateSource {
  /// The USD rate for [day], or for today when [day] is null.
  Future<OfficialRate> usd({DateTime? day});
}

/// Rates from the Central Bank of Uzbekistan (cbu.uz). Free, no key.
///
/// Answer example:
/// `[{"Ccy":"USD","Nominal":"1","Rate":"11778.45","Date":"06.10.2026"}]`
class CbuRateSource implements RateSource {
  const CbuRateSource();

  static const _base = 'https://cbu.uz/uz/arkhiv-kursov-valyut/json/USD/';
  static const _timeout = Duration(seconds: 10);

  @override
  Future<OfficialRate> usd({DateTime? day}) async {
    final path = day == null ? '' : '${_isoDate(day)}/';
    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final request = await client.getUrl(Uri.parse('$_base$path'));
      final response = await request.close().timeout(_timeout);
      if (response.statusCode != HttpStatus.ok) {
        throw RateUnavailableException('HTTP ${response.statusCode}');
      }
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(_timeout);
      return parseCbu(body);
    } on RateUnavailableException {
      rethrow;
    } on Object catch (e) {
      throw RateUnavailableException('$e');
    } finally {
      client.close(force: true);
    }
  }

  /// Reads the CBU answer. Public for tests.
  static OfficialRate parseCbu(String body) {
    try {
      final item = (jsonDecode(body) as List).first as Map<String, dynamic>;
      final rate = double.parse(item['Rate'] as String);
      final nominal = int.tryParse('${item['Nominal']}') ?? 1;
      // "06.10.2026" → 6 October 2026.
      final [d, m, y] = (item['Date'] as String)
          .split('.')
          .map(int.parse)
          .toList();
      if (rate <= 0 || nominal <= 0) throw const FormatException('bad rate');
      return OfficialRate(day: DateTime(y, m, d), rate: rate / nominal);
    } on Object catch (e) {
      throw RateUnavailableException('Unexpected answer: $e');
    }
  }

  static String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
