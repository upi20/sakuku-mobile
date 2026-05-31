import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/database/daos/history_dao.dart';
import '../../../core/database/daos/history_transfer_dao.dart';
import '../../../core/models/history_model.dart';
import '../../../core/models/history_transfer_model.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/utils/date_formatter.dart';
import '../../../shared/widgets/colored_icon.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../bloc/history_bloc.dart';
import '../bloc/transfer_bloc.dart';

class TransferDetailPage extends StatefulWidget {
  final int transferId;
  const TransferDetailPage({super.key, required this.transferId});

  @override
  State<TransferDetailPage> createState() => _TransferDetailPageState();
}

class _TransferDetailPageState extends State<TransferDetailPage> {
  HistoryTransferModel? _transfer;
  HistoryModel? _fee;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final transfer = await HistoryTransferDao().getById(widget.transferId);
      final fee = await HistoryDao().getFeeByTransferId(widget.transferId);
      if (mounted) {
        setState(() {
          _transfer = transfer;
          _fee = fee;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ConfirmDialog(
        title: 'Hapus Transfer',
        message: 'Hapus transfer ini? Semua catatan terkait akan dihapus.',
        onConfirm: () {
          context.read<TransferBloc>().add(
              TransferDeleteRequested(widget.transferId));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TransferBloc, TransferState>(
      listener: (context, state) {
        if (state is TransferDeleteSuccess) {
          context.read<HistoryBloc>().add(HistoryRefresh());
          context.pop();
        } else if (state is TransferError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detail Transfer'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _transfer == null
                  ? null
                  : () => context.push(
                      '/history/transfer/${widget.transferId}/edit'),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _transfer == null
                  ? null
                  : () => _confirmDelete(context),
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (_transfer == null) return const Center(child: Text('Tidak ditemukan'));

    final t = _transfer!;
    final srcBg = ColoredIcon.parseColor(t.srcAccountColor);
    final destBg = ColoredIcon.parseColor(t.destAccountColor);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        children: [
          // ── Card 1: Account pair ──────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            decoration: BoxDecoration(
              color: AppTheme.transfer.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _AccountColumn(
                    iconName: t.srcAccountIcon ?? 'ic_other',
                    bgColor: srcBg,
                    name: t.srcAccountName ?? '-',
                    align: CrossAxisAlignment.start,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.transfer.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppTheme.transfer,
                      size: 20,
                    ),
                  ),
                ),
                Expanded(
                  child: _AccountColumn(
                    iconName: t.destAccountIcon ?? 'ic_other',
                    bgColor: destBg,
                    name: t.destAccountName ?? '-',
                    align: CrossAxisAlignment.end,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // ── Card 2: Amount ───────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: context.cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  'JUMLAH TRANSFER',
                  style: context.tt.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: context.cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  CurrencyFormatter.format(t.amount),
                  style: context.tt.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.transfer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // ── Card 3: Date ────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: context.cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: _IconDetailRow(
              leading: const _NeutralIcon(Icons.calendar_today_outlined),
              label: 'TANGGAL',
              value: '${DateFormatter.formatDate(t.date)},  ${DateFormatter.formatTime(t.time)}',
            ),
          ),
          if (_fee != null) ...[
            const SizedBox(height: 12),
            _FeeCard(fee: _fee!),
          ],
        ],
      ),
    );
  }
}

class _AccountColumn extends StatelessWidget {
  final String iconName;
  final Color bgColor;
  final String name;
  final CrossAxisAlignment align;
  const _AccountColumn({
    required this.iconName,
    required this.bgColor,
    required this.name,
    required this.align,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        ColoredIcon(
          iconName: iconName,
          backgroundColor: bgColor,
          size: 52,
          iconSize: 28,
        ),
        const SizedBox(height: 10),
        Text(
          name,
          style: context.tt.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: context.cs.onSurface,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: align == CrossAxisAlignment.end ? TextAlign.end : TextAlign.start,
        ),
      ],
    );
  }
}

class _NeutralIcon extends StatelessWidget {
  final IconData icon;
  const _NeutralIcon(this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: context.cs.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20, color: context.cs.onSurfaceVariant),
    );
  }
}

class _IconDetailRow extends StatelessWidget {
  final Widget leading;
  final String label;
  final String value;
  const _IconDetailRow({
    required this.leading,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          leading,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.tt.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: context.cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: context.tt.bodyMedium?.copyWith(
                    color: context.cs.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeeCard extends StatelessWidget {
  final HistoryModel fee;
  const _FeeCard({required this.fee});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.expense.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_outlined,
              color: AppTheme.expense,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BIAYA TRANSFER',
                  style: context.tt.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: context.cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  fee.accountName ?? '-',
                  style: context.tt.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: context.cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(fee.amount),
            style: context.tt.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.expense,
            ),
          ),
        ],
      ),
    );
  }
}


