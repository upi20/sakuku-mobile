import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
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
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: const Text('Detail Transfer',
              style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: _transfer == null
                  ? null
                  : () => context.push(
                      '/history/transfer/${widget.transferId}/edit'),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Src → Dest
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4)
              ],
            ),
            child: Row(
              children: [
                Column(
                  children: [
                    ColoredIcon(
                        iconName: t.srcAccountIcon ?? 'ic_other',
                        backgroundColor: srcBg),
                    const SizedBox(height: 4),
                    Text(
                      t.srcAccountName ?? '-',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.darkBlue),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const Expanded(
                  child: Icon(Icons.arrow_forward,
                      color: AppColors.transfer, size: 28),
                ),
                Column(
                  children: [
                    ColoredIcon(
                        iconName: t.destAccountIcon ?? 'ic_other',
                        backgroundColor: destBg),
                    const SizedBox(height: 4),
                    Text(
                      t.destAccountName ?? '-',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.darkBlue),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Amount + Date
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4)
              ],
            ),
            child: Column(
              children: [
                _DetailRow(
                  label: 'JUMLAH',
                  value: CurrencyFormatter.format(t.amount),
                ),
                const Divider(height: 1),
                _DetailRow(
                  label: 'TANGGAL',
                  value:
                      '${DateFormatter.formatDate(t.date)}  ${DateFormatter.formatTime(t.time)}',
                ),
              ],
            ),
          ),
          // Fee card (if any)
          if (_fee != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4)
                ],
              ),
              child: Row(
                children: [
                  ColoredIcon(
                    iconName: 'ic_transfer',
                    backgroundColor: ColoredIcon.parseColor('#9e9e9e'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'BIAYA TRANSFER',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGray,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _fee!.accountName ?? '-',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(_fee!.amount),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.expense,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 15, color: AppColors.darkBlue),
          ),
        ],
      ),
    );
  }
}
