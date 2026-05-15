import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/debt_trans_model.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../bloc/debt_trans_bloc.dart';
import '../bloc/debt_trans_event.dart';
import '../bloc/debt_trans_state.dart';

class DebtTransDetailPage extends StatelessWidget {
  final int debtId;
  final int transId;
  const DebtTransDetailPage(
      {super.key, required this.debtId, required this.transId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DebtTransBloc()..add(DebtTransLoad(debtId)),
      child: _DebtTransDetailBody(debtId: debtId, transId: transId),
    );
  }
}

class _DebtTransDetailBody extends StatelessWidget {
  final int debtId;
  final int transId;
  const _DebtTransDetailBody(
      {required this.debtId, required this.transId});

  String _formatDate(String dt) {
    try {
      final d = DateTime.parse(dt.substring(0, 10));
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return dt;
    }
  }

  String _formatTime(String dt) {
    try {
      final parts = dt.split(' ');
      if (parts.length > 1) return parts[1].substring(0, 5);
    } catch (_) {}
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        elevation: 0,
        actions: [
          BlocBuilder<DebtTransBloc, DebtTransState>(
            builder: (context, state) {
              if (state is! DebtTransLoaded) return const SizedBox();
              try {
                state.transactions.firstWhere((x) => x.id == transId);
              } catch (_) {
                return const SizedBox();
              }
              return PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') {
                    context.push('/debt/$debtId/trans/$transId/edit');
                  } else if (v == 'hapus') {
                    ConfirmDialog.show(
                      context,
                      title: 'Hapus Transaksi',
                      message: 'Yakin ingin menghapus transaksi ini?',
                      onConfirm: () {
                        context.read<DebtTransBloc>().add(
                            DebtTransDelete(
                                id: transId, debtId: debtId));
                      },
                    );
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(
                      value: 'hapus',
                      child: Text('Hapus',
                          style: TextStyle(color: Theme.of(context).colorScheme.error))),
                ],
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<DebtTransBloc, DebtTransState>(
        listener: (context, state) {
          if (state is DebtTransSuccess) {
            context.pop();
          } else if (state is DebtTransError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is DebtTransLoading || state is DebtTransInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DebtTransLoaded) {
            DebtTransModel? trans;
            try {
              trans =
                  state.transactions.firstWhere((x) => x.id == transId);
            } catch (_) {}
            if (trans == null) {
              return const Center(child: Text('Transaksi tidak ditemukan'));
            }
            final isPayment = trans.type == 1;
            final color =
                isPayment ? AppTheme.income : AppTheme.expense;
            final typeLabel = isPayment ? 'PEMBAYARAN' : 'PENAMBAHAN';

            return SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.cs.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withAlpha(26),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(typeLabel,
                                  style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _LabelValue(
                          label: 'JUMLAH',
                          value: CurrencyFormatter.format(trans.amount),
                          valueStyle: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: color),
                        ),
                        const Divider(height: 24),
                        _LabelValue(
                          label: 'TANGGAL',
                          value:
                              '${_formatDate(trans.dateTime)} ${_formatTime(trans.dateTime)}',
                        ),
                        const SizedBox(height: 12),
                        _LabelValue(
                          label: 'REKENING',
                          value: trans.accountName ?? '-',
                        ),
                        const SizedBox(height: 12),
                        _LabelValue(
                          label: 'CATATAN',
                          value: trans.note.isNotEmpty ? trans.note : '-',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class _LabelValue extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;
  const _LabelValue(
      {required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: context.cs.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(value,
            style: valueStyle ??
                TextStyle(
                    fontWeight: FontWeight.bold,
                    color: context.cs.onSurface,
                    fontSize: 15)),
      ],
    );
  }
}
