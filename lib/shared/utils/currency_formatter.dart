import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String format(double amount) {
    return _formatter.format(amount);
  }

  /// Returns absolute value formatted (without negative sign).
  static String formatAbs(double amount) {
    return _formatter.format(amount.abs());
  }
}
