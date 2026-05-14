import 'package:flutter/services.dart';

/// TextInputFormatter that formats integers with dot thousands separators.
/// e.g.: typing "1500000" displays "1.500.000"
/// Raw digits are stored without separators internally.
class ThousandsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Strip all non-digit characters
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Remove leading zeros (except a single "0")
    final trimmed = digits.replaceFirst(RegExp(r'^0+'), '');
    final sanitized = trimmed.isEmpty ? '0' : trimmed;

    final formatted = _addThousandsSeparator(sanitized);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String _addThousandsSeparator(String digits) {
    final buffer = StringBuffer();
    final len = digits.length;
    for (int i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// Strips thousands separators and returns a plain integer string.
  static String toRaw(String formatted) =>
      formatted.replaceAll('.', '');

  /// Formats a plain integer/double value for display in the text field.
  static String formatForDisplay(num value) =>
      _addThousandsSeparator(value.toInt().toString());
}
