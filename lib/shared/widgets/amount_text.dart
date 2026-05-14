import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../utils/currency_formatter.dart';

/// Displays a formatted currency amount colored by sign/type.
/// - income (+) → green
/// - expense (-) → red
/// - transfer (type 2 or 4) → orange
class AmountText extends StatelessWidget {
  final double amount;
  final String sign;
  final int type;
  final TextStyle? style;

  const AmountText({
    super.key,
    required this.amount,
    required this.sign,
    this.type = 1,
    this.style,
  });

  Color get _color {
    if (type == 2 || type == 4) return AppColors.transfer;
    if (sign == '+') return AppColors.income;
    return AppColors.expense;
  }

  String get _prefix {
    if (type == 2 || type == 4) return '';
    return sign == '+' ? '+' : '-';
  }

  @override
  Widget build(BuildContext context) {
    final base = style ?? const TextStyle(fontSize: 14);
    return Text(
      '$_prefix${CurrencyFormatter.formatAbs(amount)}',
      style: base.copyWith(color: _color),
    );
  }
}
