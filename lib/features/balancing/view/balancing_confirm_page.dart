import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/widgets/colored_icon.dart';
import '../bloc/balancing_bloc.dart';
import '../model/balancing_item.dart';
import '../model/bulk_transaction_entry.dart';

class BalancingConfirmPage extends StatefulWidget {
  const BalancingConfirmPage({super.key});

  @override
  State<BalancingConfirmPage> createState() => _BalancingConfirmPageState();
}

class _BalancingConfirmPageState extends State<BalancingConfirmPage> {
  bool _isSaving = false;

  void _onSelectAccount(BuildContext context, int? accountId) {
    if (accountId == null) return;
    context.read<BalancingBloc>().add(BalancingSelectAccount(accountId));
  }

  void _save(BuildContext context) {
    context.read<BalancingBloc>().add(const BalancingSave());
  }

  /// Pop semua halaman balancing (3 level: Confirm + Bulk + Check) kembali ke Settings.
  void _popAllBalancing(BuildContext context) {
    // BalancingPage adalah root di stack; pop 3 kali agar kembali ke settings.
    int count = 0;
    Navigator.popUntil(context, (route) => count++ >= 3);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BalancingBloc, BalancingState>(
      listener: (context, state) {
        if (state is BalancingSaving) {
          setState(() => _isSaving = true);
        } else if (state is BalancingSaveSuccess) {
          setState(() => _isSaving = false);
          // Capture messenger SEBELUM pop agar context tetap valid.
          final messenger = ScaffoldMessenger.of(context);
          _popAllBalancing(context);
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Balancing berhasil disimpan'),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (state is BalancingError) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.expense,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: const Text('Konfirmasi  (Langkah 3 dari 3)'),
          elevation: 0,
        ),
        body: BlocBuilder<BalancingBloc, BalancingState>(
          // Jangan rebuild saat BalancingSaving agar konten tetap terlihat.
          buildWhen: (prev, curr) => curr is BalancingLoaded,
          builder: (context, state) {
            if (state is! BalancingLoaded) return const SizedBox.shrink();

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Pilih Rekening Balancing ──────────────
                        _SectionHeader(title: 'Rekening Balancing (Hub)'),
                        const SizedBox(height: 8),
                        _AccountDropdown(
                          items: state.items,
                          selectedId: state.balancingAccountId,
                          onChanged: (id) =>
                              _onSelectAccount(context, id),
                        ),

                        const SizedBox(height: 20),

                        // ── Preview Transfer ──────────────────────
                        _SectionHeader(
                            title: 'Transfer yang Akan Dibuat',
                            subtitle: state.balancingAccountId == null
                                ? 'Pilih rekening balancing terlebih dahulu'
                                : null),
                        const SizedBox(height: 8),
                        if (state.balancingAccountId != null) ...[
                          if (state.transferItems.isEmpty)
                            const _EmptyPreview(
                                message: 'Tidak ada selisih — tidak ada transfer')
                          else
                            ...state.transferItems.map(
                              (item) => _TransferPreviewTile(
                                item: item,
                                balancingName:
                                    _balancingName(state),
                              ),
                            ),
                        ],

                        const SizedBox(height: 20),

                        // ── Preview Bulk Transaksi ────────────────
                        _SectionHeader(
                            title: 'Transaksi yang Akan Dibuat',
                            subtitle: state.balancingAccountId == null
                                ? null
                                : 'Dari: ${_balancingName(state)}'),
                        const SizedBox(height: 8),
                        if (state.bulkEntries.isEmpty)
                          const _EmptyPreview(
                              message: 'Tidak ada catatan transaksi')
                        else
                          ...state.bulkEntries.map(
                            (entry) => _BulkPreviewTile(entry: entry),
                          ),

                        const SizedBox(height: 16),

                        // ── Total ─────────────────────────────────
                        _TotalSummaryCard(state: state),
                      ],
                    ),
                  ),
                ),

                // ── Tombol Simpan ─────────────────────────────────
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_isSaving ||
                                state.balancingAccountId == null)
                            ? null
                            : () => _save(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.divider,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            : const Text('Simpan',
                                style: TextStyle(fontSize: 15)),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _balancingName(BalancingLoaded state) {
    if (state.balancingAccountId == null) return '';
    try {
      return state.items
          .firstWhere((i) => i.account.id == state.balancingAccountId)
          .account
          .name;
    } catch (_) {
      return '';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBlue)),
        if (subtitle != null)
          Text(subtitle!,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.darkGray)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _AccountDropdown extends StatelessWidget {
  final List<BalancingItem> items;
  final int? selectedId;
  final ValueChanged<int?> onChanged;

  const _AccountDropdown({
    required this.items,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedId,
          isExpanded: true,
          hint: const Text('Pilih rekening balancing',
              style: TextStyle(color: AppColors.darkGray, fontSize: 14)),
          items: items.map((item) {
            return DropdownMenuItem<int>(
              value: item.account.id,
              child: Row(
                children: [
                  ColoredIcon(
                    iconName: item.account.icon,
                    backgroundColor:
                        ColoredIcon.parseColor(item.account.color),
                    size: 28,
                    iconSize: 16,
                  ),
                  const SizedBox(width: 10),
                  Text(item.account.name,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.darkBlue)),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TransferPreviewTile extends StatelessWidget {
  final BalancingItem item;
  final String balancingName;

  const _TransferPreviewTile(
      {required this.item, required this.balancingName});

  @override
  Widget build(BuildContext context) {
    final selisih = item.selisih;
    final isAppHigher = selisih < 0; // rekening ini kirim ke balancing

    final srcName = isAppHigher ? item.account.name : balancingName;
    final destName = isAppHigher ? balancingName : item.account.name;
    final amount = selisih.abs();

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(srcName,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.darkBlue,
                          fontWeight: FontWeight.w600)),
                  Row(
                    children: const [
                      Icon(Icons.arrow_downward,
                          size: 14, color: AppColors.primary),
                      SizedBox(width: 2),
                      Text('ke',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.darkGray)),
                    ],
                  ),
                  Text(destName,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.darkBlue,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Text(
              CurrencyFormatter.format(amount),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.expense,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _BulkPreviewTile extends StatelessWidget {
  final BulkTransactionEntry entry;

  const _BulkPreviewTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.note.isEmpty ? '(tanpa catatan)' : entry.note,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.darkBlue),
                  ),
                  if (entry.categoryName.isNotEmpty)
                    Text(entry.categoryName,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.darkGray)),
                ],
              ),
            ),
            Text(
              CurrencyFormatter.format(entry.amount),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.expense,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TotalSummaryCard extends StatelessWidget {
  final BalancingLoaded state;

  const _TotalSummaryCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          _SummaryRow(
              label: 'Total Selisih',
              value: CurrencyFormatter.format(state.totalSelisih),
              color: state.totalSelisih < 0
                  ? AppColors.expense
                  : state.totalSelisih > 0
                      ? AppColors.income
                      : AppColors.darkGray),
          const Divider(height: 12),
          _SummaryRow(
              label: 'Total Catatan',
              value: CurrencyFormatter.format(state.totalBulk),
              color: AppColors.darkBlue),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppColors.darkGray)),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color)),
      ],
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  final String message;

  const _EmptyPreview({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(message,
          style: const TextStyle(
              fontSize: 13, color: AppColors.darkGray,
              fontStyle: FontStyle.italic)),
    );
  }
}
