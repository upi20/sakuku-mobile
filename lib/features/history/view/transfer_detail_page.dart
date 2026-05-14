import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/database/daos/history_transfer_dao.dart';
import '../../../core/models/history_transfer_model.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/utils/date_formatter.dart';
import '../../../shared/widgets/colored_icon.dart';

class TransferDetailPage extends StatefulWidget {
  final int transferId;
  const TransferDetailPage({super.key, required this.transferId});

  @override
  State<TransferDetailPage> createState() => _TransferDetailPageState();
}

class _TransferDetailPageState extends State<TransferDetailPage> {
  HistoryTransferModel? _transfer;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dao = HistoryTransferDao();
      final transfer = await dao.getById(widget.transferId);
      if (mounted) {
        setState(() {
          _transfer = transfer;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Detail Transfer',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildBody(),
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
