import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../bloc/history_bloc.dart';
import '../widgets/history_date_header.dart';
import '../widgets/history_list_item.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/utils/date_formatter.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  void initState() {
    super.initState();
    // Jangan reset jika sudah ada data (misal kembali dari tab lain)
    final bloc = context.read<HistoryBloc>();
    if (bloc.state is HistoryInitial) {
      bloc.add(HistoryLoadByMonth(DateFormatter.currentYearMonth()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/history/search'),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => context.push('/history/filter'),
          ),
        ],
      ),
      body: BlocBuilder<HistoryBloc, HistoryState>(
        builder: (context, state) {
          if (state is HistoryLoading || state is HistoryInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is HistoryError) {
            return Center(child: Text(state.message));
          }
          if (state is HistoryLoaded) {
            return _HistoryBody(state: state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _HistoryBody extends StatelessWidget {
  final HistoryLoaded state;

  const _HistoryBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final income = state.summary['income'] ?? 0.0;
    final expense = state.summary['expense'] ?? 0.0;
    final total = state.summary['total'] ?? 0.0;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<HistoryBloc>().add(HistoryRefresh());
      },
      child: CustomScrollView(
        slivers: [
          // Mode tabs + nav + inline summary (one combined header)
          SliverToBoxAdapter(
            child: _buildNavBar(context, state, income, expense, total),
          ),
          // Empty state or list
          if (state.rows.isEmpty)
            const SliverFillRemaining(
              child: EmptyState(
                icon: Icons.history,
                message: 'Belum ada transaksi',
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final row = state.rows[index];
                  if (row is HistoryDateHeaderRow) {
                    return HistoryDateHeader(
                      dateNumber: row.date,
                      dayName: row.dayName,
                      monthYear: row.monthYear,
                      dailyTotal: row.total,
                    );
                  }
                  if (row is HistoryTransactionRow) {
                    final item = row.item;
                    return HistoryListItem(
                      item: item,
                      onTap: () {
                        if (item.type == 2 || item.type == 4) {
                          context.push('/history/transfer/${item.transferId}');
                        } else {
                          context.push('/history/${item.id}');
                        }
                      },
                    );
                  }
                  if (row is HistoryTransferPairRow) {
                    return _TransferPairItem(
                      row: row,
                      onTap: () => context
                          .push('/history/transfer/${row.transferId}'),
                    );
                  }
                  return null;
                },
                childCount: state.rows.length,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavBar(
    BuildContext context,
    HistoryLoaded state,
    double income,
    double expense,
    double total,
  ) {
    return _NavWithSummary(
      state: state,
      income: income,
      expense: expense,
      total: total,
    );
  }
}

class _NavWithSummary extends StatelessWidget {
  final HistoryLoaded state;
  final double income;
  final double expense;
  final double total;

  const _NavWithSummary({
    required this.state,
    required this.income,
    required this.expense,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final isNavigable = state.viewMode == HistoryViewMode.monthly ||
        state.viewMode == HistoryViewMode.yearly ||
        state.viewMode == HistoryViewMode.daily;

    return Container(
      color: context.cs.surfaceContainerLowest,
      padding: const EdgeInsets.fromLTRB(4, 2, 8, 6),
      child: Row(
        children: [
          // Left side: prev arrow + label + next arrow (or just label)
          if (isNavigable) ...[
            IconButton(
              icon: const Icon(Icons.chevron_left),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              onPressed: () {
                if (state.viewMode == HistoryViewMode.monthly) {
                  context.read<HistoryBloc>().add(HistoryChangeMonth(-1));
                } else if (state.viewMode == HistoryViewMode.yearly) {
                  context.read<HistoryBloc>().add(HistoryChangeYear(-1));
                } else {
                  context.read<HistoryBloc>().add(HistoryChangeDay(-1));
                }
              },
            ),
            GestureDetector(
              onTap: () => context.push('/history/filter'),
              child: Text(
                state.displayLabel,
                style: context.tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              onPressed: () {
                if (state.viewMode == HistoryViewMode.monthly) {
                  context.read<HistoryBloc>().add(HistoryChangeMonth(1));
                } else if (state.viewMode == HistoryViewMode.yearly) {
                  context.read<HistoryBloc>().add(HistoryChangeYear(1));
                } else {
                  context.read<HistoryBloc>().add(HistoryChangeDay(1));
                }
              },
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: GestureDetector(
                onTap: () => context.push('/history/filter'),
                child: Text(
                  state.displayLabel,
                  style: context.tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          const Spacer(),
          // Right side: tap any chip → show all in one dialog
          GestureDetector(
            onTap: () => _showSummaryDialog(context, income, expense, total),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MiniChip(icon: Icons.arrow_downward, amount: income, color: AppTheme.income),
                const SizedBox(width: 8),
                _MiniChip(icon: Icons.arrow_upward, amount: expense, color: AppTheme.expense),
                const SizedBox(width: 8),
                _MiniChip(icon: Icons.account_balance_wallet, amount: total, color: AppTheme.balanced),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _showSummaryDialog(
  BuildContext context,
  double income,
  double expense,
  double total,
) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Ringkasan'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SummaryDialogRow(
            label: 'Pemasukan',
            amount: income,
            color: AppTheme.income,
          ),
          const SizedBox(height: 8),
          _SummaryDialogRow(
            label: 'Pengeluaran',
            amount: expense,
            color: AppTheme.expense,
          ),
          const Divider(height: 16),
          _SummaryDialogRow(
            label: 'Net',
            amount: total,
            color: AppTheme.balanced,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Tutup'),
        ),
      ],
    ),
  );
}

class _SummaryDialogRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _SummaryDialogRow({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: context.tt.bodyMedium),
        ),
        Text(
          CurrencyFormatter.format(amount),
          style: context.tt.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final double amount;
  final Color color;

  const _MiniChip({required this.icon, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 2),
        Text(
          CurrencyFormatter.formatCompact(amount),
          style: context.tt.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _TransferPairItem extends StatelessWidget {
  final HistoryTransferPairRow row;
  final VoidCallback? onTap;

  const _TransferPairItem({required this.row, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Material(
        color: context.cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.transfer.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.swap_horiz,
                      color: AppTheme.transfer, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              'Transfer Saldo',
                              style: context.tt.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: context.cs.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            CurrencyFormatter.formatCompact(row.amount),
                            style: context.tt.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.transfer,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.swap_horiz,
                              size: 14, color: AppTheme.transfer),
                        ],
                      ),
                      Text(
                        '${row.srcAccountName} → ${row.destAccountName}',
                        style: context.tt.bodySmall?.copyWith(
                          color: context.cs.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
