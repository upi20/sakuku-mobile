import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/currency_formatter.dart';

/// Date group header matching item_history_header.xml.
/// Left: date number | Middle: day name + month-year | Right: daily total
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
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.cs.surface,
      ),
      child: Row(
        children: [
          // Date number box
          SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: Text(
                dateNumber,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.cs.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Day name + Month Year
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayName,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.cs.onSurface,
                  ),
                ),
                Text(
                  monthYear,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Daily total
          Text(
            CurrencyFormatter.format(dailyTotal),
            style: TextStyle(
              fontSize: 13,
              color: context.cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
