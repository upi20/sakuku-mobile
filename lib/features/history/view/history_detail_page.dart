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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Icon + category + amount
          Center(
            child: Column(
              children: [
                ColoredIcon(iconName: iconName, backgroundColor: bgColor, size: 64, iconSize: 36),
                const SizedBox(height: 8),
                Text(
                  item.categoryName ?? '-',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                AmountText(
                  amount: item.amount,
                  sign: item.sign,
                  type: item.type,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Detail rows
          _DetailCard(children: [
            _DetailRow(label: 'REKENING', value: item.accountName ?? '-'),
            const Divider(height: 1),
            _DetailRow(
              label: 'TANGGAL',
              value: '${DateFormatter.formatDate(item.date)}  ${DateFormatter.formatTime(item.time)}',
            ),
            if (item.note.trim().isNotEmpty) ...[
              const Divider(height: 1),
              _DetailRow(label: 'CATATAN', value: item.note),
            ],
          ]),
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

class _DetailCard extends StatelessWidget {
  final List<Widget> children;
  const _DetailCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(children: children),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 15),
          ),
        ],
      ),
    );
  }
}
