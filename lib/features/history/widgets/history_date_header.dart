import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/currency_formatter.dart';

/// Date group header — compact single-line high-density redesign.
/// Layout: [dateNumber DayName, MonthYear] ············ [colored daily total]
class HistoryDateHeader extends StatelessWidget {
  final String dateNumber;   // e.g. "15"
  final String dayName;      // e.g. "Senin"
  final String monthYear;    // e.g. "Januari 2024"
  final double dailyTotal;

  const HistoryDateHeader({
    super.key,
    required this.dateNumber,
    required this.dayName,
    required this.monthYear,
    required this.dailyTotal,
  });

  @override
  Widget build(BuildContext context) {
    final totalColor = dailyTotal >= 0 ? AppTheme.income : AppTheme.expense;
    final totalText =
        '${dailyTotal >= 0 ? '+' : ''}${CurrencyFormatter.format(dailyTotal)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: context.cs.surfaceContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
        children: [
          // Date number bold + day + month inline
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$dateNumber  ',
                    style: context.tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.cs.primary,
                    ),
                  ),
                  TextSpan(
                    text: '$dayName, $monthYear',
                    style: context.tt.bodySmall?.copyWith(
                      color: context.cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Daily total with semantic color
          Text(
            totalText,
            style: context.tt.labelMedium?.copyWith(
              color: totalColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      ),
    );
  }
}
