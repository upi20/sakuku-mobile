import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/utils/currency_formatter.dart';

/// Summary card shown at top of HistoryPage matching layout_summary_history
/// from history_fragment.xml.
class HistorySummaryCard extends StatelessWidget {
  final double income;
  final double expense;
  final double total;

  const HistorySummaryCard({
    super.key,
    required this.income,
    required this.expense,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 8, 0, 0),
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
      ),
      child: Column(
        children: [
          _SummaryRow(
            label: 'Pemasukan',
            amount: income,
            amountColor: AppColors.income,
          ),
          const SizedBox(height: 4),
          _SummaryRow(
            label: 'Pengeluaran',
            amount: expense,
            amountColor: AppColors.expense,
          ),
          const SizedBox(height: 6),
          const Divider(color: AppColors.lightBlue, height: 1, thickness: 1),
          const SizedBox(height: 6),
          _SummaryRow(
            label: 'Total',
            amount: total,
            amountColor: AppColors.balance,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color amountColor;

  const _SummaryRow({
    required this.label,
    required this.amount,
    required this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.darkBlue,
          ),
        ),
        Expanded(
          child: Text(
            CurrencyFormatter.format(amount),
            textAlign: TextAlign.end,
            style: TextStyle(fontSize: 14, color: amountColor),
          ),
        ),
      ],
    );
  }
}
