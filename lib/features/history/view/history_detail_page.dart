import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/history_model.dart';
import '../../../core/repositories/interfaces/i_history_repository.dart';
import '../../../shared/widgets/colored_icon.dart';
import '../../../shared/widgets/amount_text.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/utils/date_formatter.dart';
import '../bloc/history_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HistoryDetailPage extends StatefulWidget {
  final int historyId;

  const HistoryDetailPage({super.key, required this.historyId});

  @override
  State<HistoryDetailPage> createState() => _HistoryDetailPageState();
}

class _HistoryDetailPageState extends State<HistoryDetailPage> {
  HistoryModel? _item;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = context.read<IHistoryRepository>();
      final item = await repo.getById(widget.historyId);
      if (!mounted) return;
      setState(() { _item = item; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeLabel = _item == null
        ? 'Detail Transaksi'
        : _item!.sign == '+' ? 'Detail Pemasukan' : 'Detail Pengeluaran';
    return Scaffold(
      appBar: AppBar(
        title: Text(typeLabel),
        actions: _item != null && _item!.type == 1
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final bloc = context.read<HistoryBloc>();
                    await context.push('/history/${_item!.id}/edit');
                    if (mounted) {
                      bloc.add(HistoryRefresh());
                      _load();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _confirmDelete,
                ),
              ]
            : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (_item == null) return const Center(child: Text('Tidak ditemukan'));

    final item = _item!;
    final iconName = item.categoryIcon ?? 'ic_other';
    final bgColor = ColoredIcon.parseColor(item.categoryColor);
    final accountBgColor = ColoredIcon.parseColor(item.accountColor);
    final semanticColor = item.sign == '+' ? AppTheme.income : AppTheme.expense;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        children: [
          // ── Hero Card ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              color: semanticColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                ColoredIcon(
                  iconName: iconName,
                  backgroundColor: bgColor,
                  size: 68,
                  iconSize: 38,
                ),
                const SizedBox(height: 12),
                Text(
                  item.categoryName ?? '-',
                  style: context.tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.cs.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                AmountText(
                  amount: item.amount,
                  sign: item.sign,
                  type: item.type,
                  style: context.tt.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // ── Detail Card ────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: context.cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _IconDetailRow(
                  leading: ColoredIcon(
                    iconName: item.accountIcon ?? 'ic_other',
                    backgroundColor: accountBgColor,
                    size: 40,
                    iconSize: 22,
                  ),
                  label: 'REKENING',
                  value: item.accountName ?? '-',
                ),
                const _RowDivider(),
                _IconDetailRow(
                  leading: const _NeutralIcon(Icons.calendar_today_outlined),
                  label: 'TANGGAL',
                  value: '${DateFormatter.formatDate(item.date)},  ${DateFormatter.formatTime(item.time)}',
                ),
                if (item.note.trim().isNotEmpty) ...[
                  const _RowDivider(),
                  _IconDetailRow(
                    leading: const _NeutralIcon(Icons.notes_rounded),
                    label: 'CATATAN',
                    value: item.note,
                    italic: true,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    ConfirmDialog.show(
      context,
      title: 'Hapus Transaksi',
      message: 'Yakin ingin menghapus transaksi ini?',
      confirmLabel: 'Hapus',
      onConfirm: () {
        context.read<HistoryBloc>().add(HistoryDeleteRequested(_item!.id!));
        context.pop();
      },
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

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 70,
      endIndent: 16,
      color: context.cs.outlineVariant,
    );
  }
}

class _IconDetailRow extends StatelessWidget {
  final Widget leading;
  final String label;
  final String value;
  final bool italic;
  const _IconDetailRow({
    required this.leading,
    required this.label,
    required this.value,
    this.italic = false,
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
                    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
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
