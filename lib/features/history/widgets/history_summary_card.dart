import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/currency_formatter.dart';

/// Compact horizontal summary strip shown at top of HistoryPage.
/// High-density design: In / Out / Net in a single row.
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: context.cs.surfaceContainerLow,
      child: Row(
        children: [
          Expanded(
            child: _SummaryChip(
              label: 'Masuk',
              amount: income,
              color: AppTheme.income,
            ),
          ),
          Container(width: 1, height: 28, color: context.cs.outlineVariant),
          Expanded(
            child: _SummaryChip(
              label: 'Keluar',
              amount: expense,
              color: AppTheme.expense,
            ),
          ),
          Container(width: 1, height: 28, color: context.cs.outlineVariant),
          Expanded(
            child: _SummaryChip(
              label: 'Net',
              amount: total,
              color: AppTheme.balanced,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: context.tt.labelSmall?.copyWith(
            color: context.cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          CurrencyFormatter.formatCompact(amount),
          style: context.tt.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
