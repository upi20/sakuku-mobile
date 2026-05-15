import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/debt_model.dart';
import '../../../core/models/debt_trans_model.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../bloc/debt_bloc.dart';
import '../bloc/debt_event.dart';
import '../bloc/debt_state.dart';
import '../bloc/debt_trans_bloc.dart';
import '../bloc/debt_trans_event.dart';
import '../bloc/debt_trans_state.dart';

class DebtDetailPage extends StatelessWidget {
  final int debtId;
  const DebtDetailPage({super.key, required this.debtId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => DebtBloc()..add(DebtLoadDetail(debtId)),
        ),
        BlocProvider(
          create: (_) => DebtTransBloc()..add(DebtTransLoad(debtId)),
        ),
      ],
      child: _DebtDetailBody(debtId: debtId),
    );
  }
}

class _DebtDetailBody extends StatelessWidget {
  final int debtId;
  const _DebtDetailBody({required this.debtId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail'),
        elevation: 0,
        actions: [
          BlocBuilder<DebtBloc, DebtState>(
            builder: (context, state) {
              if (state is DebtDetailLoaded) {
                return PopupMenuButton<String>(
                  onSelected: (v) => _onMenu(context, v, state.debt),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(
                        value: 'delete',
                        child: Text('Hapus',
                            style: TextStyle(color: Theme.of(context).colorScheme.error))),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocListener<DebtBloc, DebtState>(
        listener: (context, state) {
          if (state is DebtSuccess) {
            context.pop();
          } else if (state is DebtError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message)),
            );
          }
        },
        child: BlocBuilder<DebtBloc, DebtState>(
          builder: (context, state) {
            if (state is DebtLoading || state is DebtInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is DebtDetailLoaded) {
              return _buildContent(context, state.debt);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/debt/$debtId/trans/add');
          if (context.mounted) {
            context.read<DebtBloc>().add(DebtLoadDetail(debtId));
            context.read<DebtTransBloc>().add(DebtTransLoad(debtId));
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _onMenu(BuildContext context, String action, DebtModel debt) {
    if (action == 'edit') {
      context.push('/debt/${debt.id}/edit').then((_) {
        if (context.mounted) {
          context.read<DebtBloc>().add(DebtLoadDetail(debtId));
          context.read<DebtTransBloc>().add(DebtTransLoad(debtId));
        }
      });
    } else if (action == 'delete') {
      ConfirmDialog.show(
        context,
        title: 'Hapus ${debt.isDebt ? 'Hutang' : 'Piutang'}',
        message:
            'Semua transaksi terkait akan ikut dihapus. Lanjutkan?',
        confirmLabel: 'Hapus',
        onConfirm: () => context.read<DebtBloc>().add(DebtDelete(debt.id!)),
      );
    }
  }

  Widget _buildContent(BuildContext context, DebtModel debt) {
    final paid = debt.paidAmount ?? 0;
    final progress =
        debt.totalAmount > 0 ? (paid / debt.totalAmount).clamp(0.0, 1.0) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Card
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Type badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: debt.isDebt
                            ? AppTheme.expense.withValues(alpha: 0.12)
                            : AppTheme.income.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        debt.isDebt ? 'HUTANG' : 'PIUTANG',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: debt.isDebt
                                ? AppTheme.expense
                                : AppTheme.income),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _LabelValue(label: 'NAMA', value: debt.name),
                  _LabelValue(
                      label: 'REKENING',
                      value: debt.accountName ?? '-'),
                  _LabelValue(
                      label: 'TANGGAL MULAI',
                      value: debt.startDateTime.length >= 10
                          ? debt.startDateTime.substring(0, 10)
                          : debt.startDateTime),
                  _LabelValue(
                      label: 'JATUH TEMPO',
                      value: debt.endDateTime.isNotEmpty
                          ? debt.endDateTime.substring(0, 10)
                          : '-'),
                  if (debt.note.isNotEmpty)
                    _LabelValue(label: 'CATATAN', value: debt.note),
                  _LabelValue(
                      label: 'JUMLAH',
                      value: CurrencyFormatter.format(debt.amount)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Progress card
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TERBAYAR',
                              style: TextStyle(fontSize: 11)),
                          Text(CurrencyFormatter.format(paid),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppTheme.income)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('SISA',
                              style: TextStyle(fontSize: 11)),
                          Text(
                              CurrencyFormatter.format(
                                  debt.remainingAmount.clamp(0, double.infinity)),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: context.cs.onSurface)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: context.cs.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(AppTheme.income),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Transactions list
          const Text('RIWAYAT TRANSAKSI',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          BlocBuilder<DebtTransBloc, DebtTransState>(
            builder: (context, state) {
              if (state is DebtTransLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is DebtTransLoaded) {
                if (state.transactions.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                        child: Text('Belum ada transaksi',
                            style: TextStyle(color: context.cs.onSurfaceVariant))),
                  );
                }
                return Column(
                  children: state.transactions
                      .map((t) => _TransItem(
                            trans: t,
                            debtId: debtId,
                            onChanged: () {
                              context
                                  .read<DebtBloc>()
                                  .add(DebtLoadDetail(debtId));
                              context
                                  .read<DebtTransBloc>()
                                  .add(DebtTransLoad(debtId));
                            },
                          ))
                      .toList(),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}

class _LabelValue extends StatelessWidget {
  final String label;
  final String value;
  const _LabelValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _TransItem extends StatelessWidget {
  final DebtTransModel trans;
  final int debtId;
  final VoidCallback onChanged;

  const _TransItem(
      {required this.trans, required this.debtId, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isPembayaran = trans.type == 1;
    final iconColor = isPembayaran ? AppTheme.income : AppTheme.expense;
    final iconData = isPembayaran ? Icons.payment : Icons.add_circle_outline;
    final label = isPembayaran ? 'Pembayaran' : 'Penambahan';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          await context
              .push('/debt/$debtId/trans/${trans.id}/detail');
          onChanged();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(iconData, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        trans.dateTime.length >= 10
                            ? trans.dateTime.substring(0, 10)
                            : trans.dateTime,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: context.cs.onSurface)),
                    Text(label,
                        style: TextStyle(fontSize: 12, color: iconColor)),
                    if (trans.note.isNotEmpty)
                      Text(trans.note,
                          style: TextStyle(
                              fontSize: 12, color: context.cs.onSurfaceVariant)),
                  ],
                ),
              ),
              Text(
                CurrencyFormatter.format(trans.amount),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: iconColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
