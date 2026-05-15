import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
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
            ),
          );
        } else if (state is BalancingError) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: context.cs.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
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
                      child: FilledButton(
                        onPressed: (_isSaving ||
                                state.balancingAccountId == null)
                            ? null
                            : () => _save(context),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Simpan'),
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
            style: context.tt.titleSmall?.copyWith(
                fontWeight: FontWeight.bold)),
        if (subtitle != null)
          Text(subtitle!,
              style: context.tt.bodySmall?.copyWith(
                  color: context.cs.onSurfaceVariant)),
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
        color: context.cs.surfaceContainerLowest,
        border: Border.all(color: context.cs.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedId,
          isExpanded: true,
          hint: Text('Pilih rekening balancing',
              style: TextStyle(color: context.cs.onSurfaceVariant, fontSize: 14)),
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
                      style: const TextStyle(fontSize: 14)),
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
                      style: context.tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600)),
                  Row(
                    children: [
                      Icon(Icons.arrow_downward,
                          size: 14, color: context.cs.primary),
                      const SizedBox(width: 2),
                      Text('ke',
                          style: context.tt.bodySmall?.copyWith(
                              color: context.cs.onSurfaceVariant)),
                    ],
                  ),
                  Text(destName,
                      style: context.tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Text(
              CurrencyFormatter.format(amount),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.transfer,
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
                    style: context.tt.bodyMedium,
                  ),
                  if (entry.categoryName.isNotEmpty)
                    Text(entry.categoryName,
                        style: context.tt.bodySmall?.copyWith(
                            color: context.cs.onSurfaceVariant)),
                ],
              ),
            ),
            Text(
              CurrencyFormatter.format(entry.amount),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.expense,
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
        color: context.cs.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _SummaryRow(
              label: 'Total Selisih',
              value: CurrencyFormatter.format(state.totalSelisih),
              color: state.totalSelisih < 0
                  ? AppTheme.expense
                  : state.totalSelisih > 0
                      ? AppTheme.income
                      : context.cs.onSurfaceVariant),
          const Divider(height: 12),
          _SummaryRow(
              label: 'Total Catatan',
              value: CurrencyFormatter.format(state.totalBulk),
              color: context.cs.onSurface),
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
            style: TextStyle(
                fontSize: 13, color: context.cs.onSurfaceVariant)),
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
          style: context.tt.bodySmall?.copyWith(
              color: context.cs.onSurfaceVariant,
              fontStyle: FontStyle.italic)),
    );
  }
}
