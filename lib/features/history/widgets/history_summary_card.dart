import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
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
      decoration: BoxDecoration(
        color: context.cs.surface,
      ),
      child: Column(
        children: [
          _SummaryRow(
            label: 'Pemasukan',
            amount: income,
            amountColor: AppTheme.income,
          ),
          const SizedBox(height: 4),
          _SummaryRow(
            label: 'Pengeluaran',
            amount: expense,
            amountColor: AppTheme.expense,
          ),
          const SizedBox(height: 6),
          const Divider(height: 1),
          const SizedBox(height: 6),
          _SummaryRow(
            label: 'Total',
            amount: total,
            amountColor: AppTheme.balanced,
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
          style: TextStyle(fontSize: 14, color: context.cs.onSurface),
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
