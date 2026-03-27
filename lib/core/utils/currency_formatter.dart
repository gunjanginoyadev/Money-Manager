import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _format = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs ',
    decimalDigits: 0,
  );

  static final NumberFormat _rupee = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static String format(num value) => _format.format(value);

  /// Indian grouping with ₹ (matches reference UI).
  static String formatRupee(num value) => _rupee.format(value);

  static String formatRupeeSigned(num value) {
    if (value < 0) return '-${_rupee.format(value.abs())}';
    return _rupee.format(value);
  }
}
