import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/debt_model.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/widgets/empty_state.dart';
import '../bloc/debt_bloc.dart';
import '../bloc/debt_event.dart';
import '../bloc/debt_state.dart';

class DebtListPage extends StatelessWidget {
  final int type; // 1=hutang, 2=piutang

  const DebtListPage({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DebtBloc()..add(DebtLoad(type)),
      child: _DebtListBody(type: type),
    );
  }
}

class _DebtListBody extends StatefulWidget {
  final int type;
  const _DebtListBody({required this.type});

  @override
  State<_DebtListBody> createState() => _DebtListBodyState();
}

class _DebtListBodyState extends State<_DebtListBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _title => widget.type == 1 ? 'Hutang' : 'Piutang';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(_title),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Belum Lunas'),
            Tab(text: 'Lunas'),
          ],
        ),
      ),
      body: BlocBuilder<DebtBloc, DebtState>(
        builder: (context, state) {
          if (state is DebtLoading || state is DebtInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DebtLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                _DebtList(
                  items: state.unpaid,
                  type: widget.type,
                  onRefresh: () =>
                      context.read<DebtBloc>().add(DebtLoad(widget.type)),
                ),
                _DebtList(
                  items: state.paid,
                  type: widget.type,
                  onRefresh: () =>
                      context.read<DebtBloc>().add(DebtLoad(widget.type)),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/debt/add?type=${widget.type}');
          if (context.mounted) {
            context.read<DebtBloc>().add(DebtLoad(widget.type));
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _DebtList extends StatelessWidget {
  final List<DebtModel> items;
  final int type;
  final VoidCallback onRefresh;

  const _DebtList({
    required this.items,
    required this.type,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.credit_card_off_outlined,
        message: 'Tidak ada data',
      );
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        itemCount: items.length,
        itemBuilder: (context, i) => _DebtListItem(
          debt: items[i],
          onTap: () async {
            await context.push('/debt/${items[i].id}/detail');
            onRefresh();
          },
        ),
      ),
    );
  }
}

class _DebtListItem extends StatelessWidget {
  final DebtModel debt;
  final VoidCallback onTap;

  const _DebtListItem({required this.debt, required this.onTap});

  bool get _isOverdue {
    if (debt.endDateTime.isEmpty) return false;
    try {
      return DateTime.parse(debt.endDateTime).isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final paid = debt.paidAmount ?? 0;
    final progress = debt.totalAmount > 0 ? (paid / debt.totalAmount).clamp(0.0, 1.0) : 0.0;
    final overdue = _isOverdue && !debt.isRelief;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      color: AppColors.darkBlue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      debt.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.darkBlue),
                    ),
                  ),
                  if (overdue)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.dueDate.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Jatuh Tempo',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.dueDate,
                              fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              if (debt.note.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(debt.note,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.darkGray)),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TERBAYAR',
                            style: TextStyle(
                                fontSize: 10, color: AppColors.darkGray)),
                        Text(CurrencyFormatter.format(paid),
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.income)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('TOTAL',
                            style: TextStyle(
                                fontSize: 10, color: AppColors.darkGray)),
                        Text(CurrencyFormatter.format(debt.amount),
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkBlue)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.divider,
                  valueColor: const AlwaysStoppedAnimation(AppColors.income),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    debt.endDateTime.isNotEmpty
                        ? 'Jatuh tempo: ${debt.endDateTime.substring(0, 10)}'
                        : 'Tanpa jatuh tempo',
                    style: TextStyle(
                        fontSize: 11,
                        color: overdue ? AppColors.dueDate : AppColors.darkGray),
                  ),
                  Text(
                    'Sisa: ${CurrencyFormatter.format(debt.remainingAmount)}',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBlue),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
