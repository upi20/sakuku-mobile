import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
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
      appBar: AppBar(
        title: Text(_title),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
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

  String get _initial {
    final n = debt.name.trim();
    return n.isEmpty ? '?' : n[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final paid = debt.paidAmount ?? 0;
    final progress =
        debt.totalAmount > 0 ? (paid / debt.totalAmount).clamp(0.0, 1.0) : 0.0;
    final overdue = _isOverdue && !debt.isRelief;
    final color = debt.type == 1 ? AppTheme.expense : AppTheme.income;
    final endDate =
        debt.endDateTime.isNotEmpty ? debt.endDateTime.substring(0, 10) : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Circular progress ring + initial avatar ──
              _ProgressRing(
                progress: progress,
                initial: _initial,
                color: color,
              ),
              const SizedBox(width: 14),
              // ── Main content ─────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            debt.name,
                            style: context.tt.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: context.cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (overdue) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.dueDate.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Jatuh Tempo',
                              style: context.tt.labelSmall?.copyWith(
                                color: AppTheme.dueDate,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (debt.note.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        debt.note,
                        style: context.tt.bodySmall?.copyWith(
                          color: context.cs.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            endDate != null
                                ? 'J.T.: $endDate'
                                : 'Tanpa jatuh tempo',
                            style: context.tt.bodySmall?.copyWith(
                              color: overdue
                                  ? AppTheme.dueDate
                                  : context.cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Text(
                          'Sisa ${CurrencyFormatter.formatCompact(debt.remainingAmount)}',
                          style: context.tt.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final double progress;
  final String initial;
  final Color color;

  const _ProgressRing({
    required this.progress,
    required this.initial,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 4,
              backgroundColor: context.cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: context.tt.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
