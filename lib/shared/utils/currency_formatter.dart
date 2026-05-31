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

  /// Returns compact/abbreviated format suitable for high-density displays.
  /// Examples: Rp 12.3jt, Rp 500rb, Rp 800
  static String formatCompact(double amount) {
    final abs = amount.abs();
    final sign = amount < 0 ? '-' : '';
    if (abs >= 1000000) {
      final val = abs / 1000000;
      final str = val % 1 == 0 ? '${val.toInt()}jt' : '${val.toStringAsFixed(1)}jt';
      return '${sign}Rp $str';
    } else if (abs >= 1000) {
      final val = abs / 1000;
      final str = val % 1 == 0 ? '${val.toInt()}rb' : '${val.toStringAsFixed(1)}rb';
      return '${sign}Rp $str';
    }
    return _formatter.format(amount);
  }

  /// Returns a TTS-friendly string readable in Indonesian.
  /// e.g. 35000 → "35 ribu rupiah", 1500000 → "1 juta 500 ribu rupiah"
  static String formatForSpeech(double amount) {
    final n = amount.abs().toInt();
    if (n == 0) return 'nol rupiah';
    final juta = n ~/ 1000000;
    final ribu = (n % 1000000) ~/ 1000;
    final sisa = n % 1000;
    final parts = <String>[];
    if (juta > 0) parts.add('$juta juta');
    if (ribu > 0) parts.add('$ribu ribu');
    if (sisa > 0) parts.add('$sisa');
    return '${parts.join(' ')} rupiah';
  }
}
