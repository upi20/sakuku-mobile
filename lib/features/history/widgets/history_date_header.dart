import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
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
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
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
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBlue,
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
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.darkBlue,
                  ),
                ),
                Text(
                  monthYear,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.darkGray,
                  ),
                ),
              ],
            ),
          ),
          // Daily total
          Text(
            CurrencyFormatter.format(dailyTotal),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.darkBlue,
            ),
          ),
        ],
      ),
    );
  }
}
