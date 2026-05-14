import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../bloc/history_bloc.dart';
import '../widgets/history_summary_card.dart';
import '../widgets/history_date_header.dart';
import '../widgets/history_list_item.dart';
import '../../../shared/widgets/empty_state.dart';
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
    context
        .read<HistoryBloc>()
        .add(HistoryLoadByMonth(DateFormatter.currentYearMonth()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Riwayat',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => context.push('/history/search'),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
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
          // Month navigation bar
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left,
                        color: AppColors.darkBlue),
                    onPressed: () => context
                        .read<HistoryBloc>()
                        .add(HistoryChangeMonth(-1)),
                  ),
                  Text(
                    state.displayMonth,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBlue,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right,
                        color: AppColors.darkBlue),
                    onPressed: () => context
                        .read<HistoryBloc>()
                        .add(HistoryChangeMonth(1)),
                  ),
                ],
              ),
            ),
          ),
          // Summary card
          SliverToBoxAdapter(
            child: HistorySummaryCard(
              income: income,
              expense: expense,
              total: total,
            ),
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
                  return null;
                },
                childCount: state.rows.length,
              ),
            ),
        ],
      ),
    );
  }
}
