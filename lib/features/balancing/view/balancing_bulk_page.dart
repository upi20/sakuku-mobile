import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/database/daos/category_dao.dart';
import '../../../core/models/category_model.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/utils/thousands_formatter.dart';
import '../bloc/balancing_bloc.dart';
import '../model/bulk_transaction_entry.dart';
import 'balancing_confirm_page.dart';

class BalancingBulkPage extends StatefulWidget {
  const BalancingBulkPage({super.key});

  @override
  State<BalancingBulkPage> createState() => _BalancingBulkPageState();
}

class _BalancingBulkPageState extends State<BalancingBulkPage> {
  // Controllers dikelola paralel dengan state.bulkEntries
  final List<TextEditingController> _noteControllers = [];
  final List<TextEditingController> _amountControllers = [];

  List<CategoryModel> _categories = [];
  bool _categoriesLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    // Sinkronisasi controller dengan state awal
    final state = context.read<BalancingBloc>().state;
    if (state is BalancingLoaded) {
      _syncControllers(state.bulkEntries.length);
    }
  }

  Future<void> _loadCategories() async {
    final cats = await CategoryDao().getBySign('-');
    if (mounted) {
      setState(() {
        _categories = cats;
        _categoriesLoaded = true;
      });
    }
  }

  void _syncControllers(int targetLength) {
    while (_noteControllers.length < targetLength) {
      _noteControllers.add(TextEditingController());
      _amountControllers.add(TextEditingController());
    }
    while (_noteControllers.length > targetLength) {
      _noteControllers.removeLast().dispose();
      _amountControllers.removeLast().dispose();
    }
  }

  @override
  void dispose() {
    for (final c in _noteControllers) {
      c.dispose();
    }
    for (final c in _amountControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addEntry(BuildContext context) {
    context.read<BalancingBloc>().add(const BalancingAddBulkEntry());
    _noteControllers.add(TextEditingController());
    _amountControllers.add(TextEditingController());
  }

  void _removeEntry(BuildContext context, int index) {
    context.read<BalancingBloc>().add(BalancingRemoveBulkEntry(index));
    _noteControllers[index].dispose();
    _amountControllers[index].dispose();
    _noteControllers.removeAt(index);
    _amountControllers.removeAt(index);
  }

  void _updateEntry(BuildContext context, int index, BulkTransactionEntry current,
      {String? note, double? amount, int? categoryId, String? categoryName}) {
    final updated = current.copyWith(
      note: note,
      amount: amount,
      categoryId: categoryId,
      categoryName: categoryName,
    );
    context
        .read<BalancingBloc>()
        .add(BalancingUpdateBulkEntry(index, updated));
  }

  void _goNext(BuildContext context) {
    final state = context.read<BalancingBloc>().state;
    if (state is BalancingLoaded) {
      for (int i = 0; i < state.bulkEntries.length; i++) {
        final e = state.bulkEntries[i];
        if (e.note.trim().isEmpty) {
          _showValidationError(context, 'Baris ${i + 1}: catatan wajib diisi');
          return;
        }
        if (e.amount <= 0) {
          _showValidationError(context, 'Baris ${i + 1}: nominal wajib diisi');
          return;
        }
        if (e.categoryId == 0) {
          _showValidationError(context, 'Baris ${i + 1}: kategori wajib dipilih');
          return;
        }
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<BalancingBloc>(),
          child: const BalancingConfirmPage(),
        ),
      ),
    );
  }

  void _showValidationError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppColors.expense,
    ));
  }

  void _showCategoryPicker(
      BuildContext context, int index, BulkTransactionEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _CategoryPickerSheet(
        categories: _categories,
        selectedId: entry.categoryId,
        onSelected: (cat) {
          _updateEntry(context, index, entry,
              categoryId: cat.id!, categoryName: cat.name);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Catatan Transaksi  (Langkah 2 dari 3)'),
        elevation: 0,
      ),
      body: BlocBuilder<BalancingBloc, BalancingState>(
        builder: (context, state) {
          if (state is! BalancingLoaded) return const SizedBox.shrink();

          // Pastikan controller selalu sinkron
          _syncControllers(state.bulkEntries.length);

          return Column(
            children: [
              // ── Info: Total Selisih, Total Catatan, Sisa ──
              _InfoBanner(
                totalSelisih: state.totalSelisih,
                totalBulk: state.totalBulk,
                sisaSelisih: state.sisaSelisih,
              ),

              // ── List entri ───────────────────────────────────
              Expanded(
                child: state.bulkEntries.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada catatan.\nTambah baris untuk mulai.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.darkGray),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                        itemCount: state.bulkEntries.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 10),
                        itemBuilder: (ctx, index) {
                          final entry = state.bulkEntries[index];
                          return _BulkEntryCard(
                            index: index,
                            entry: entry,
                            noteController: _noteControllers[index],
                            amountController: _amountControllers[index],
                            categoriesLoaded: _categoriesLoaded,
                            onNoteChanged: (val) =>
                                _updateEntry(context, index, entry, note: val),
                            onAmountChanged: (val) {
                              final raw = ThousandsInputFormatter.toRaw(val);
                              final amount = double.tryParse(raw) ?? 0;
                              _updateEntry(context, index, entry,
                                  amount: amount);
                            },
                            onCategoryTap: () =>
                                _showCategoryPicker(context, index, entry),
                            onDelete: () => _removeEntry(context, index),
                          );
                        },
                      ),
              ),

              // ── Tambah baris ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: OutlinedButton.icon(
                  onPressed: () => _addEntry(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah Baris'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    minimumSize: const Size.fromHeight(40),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),

              // ── Tombol Lanjut ─────────────────────────────────
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _goNext(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Lanjut  →',
                          style: TextStyle(fontSize: 15)),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final double totalSelisih;
  final double totalBulk;
  final double sisaSelisih;

  const _InfoBanner({
    required this.totalSelisih,
    required this.totalBulk,
    required this.sisaSelisih,
  });

  @override
  Widget build(BuildContext context) {
    final selisihColor = totalSelisih < 0
        ? AppColors.expense
        : totalSelisih > 0
            ? AppColors.income
            : AppColors.darkGray;

    final sisaColor = sisaSelisih == 0
        ? AppColors.income              // pas → hijau
        : const Color(0xFFFF8F00);      // masih kurang / melebihi → oranye

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _BannerCell(
                  label: 'Total Selisih',
                  value: CurrencyFormatter.format(totalSelisih),
                  valueColor: selisihColor,
                ),
              ),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(
                child: _BannerCell(
                  label: 'Total Catatan',
                  value: CurrencyFormatter.format(totalBulk),
                  valueColor: AppColors.darkBlue,
                  align: TextAlign.end,
                ),
              ),
            ],
          ),
          const Divider(height: 12, thickness: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sisa yang belum dijelaskan',
                  style: TextStyle(fontSize: 11, color: AppColors.darkGray)),
              Text(
                sisaSelisih == 0
                    ? 'Rp 0  ✓'
                    : CurrencyFormatter.format(sisaSelisih),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: sisaColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerCell extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final TextAlign align;

  const _BannerCell({
    required this.label,
    required this.value,
    required this.valueColor,
    this.align = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align == TextAlign.end
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.darkGray)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: valueColor)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _BulkEntryCard extends StatelessWidget {
  final int index;
  final BulkTransactionEntry entry;
  final TextEditingController noteController;
  final TextEditingController amountController;
  final bool categoriesLoaded;
  final ValueChanged<String> onNoteChanged;
  final ValueChanged<String> onAmountChanged;
  final VoidCallback onCategoryTap;
  final VoidCallback onDelete;

  const _BulkEntryCard({
    required this.index,
    required this.entry,
    required this.noteController,
    required this.amountController,
    required this.categoriesLoaded,
    required this.onNoteChanged,
    required this.onAmountChanged,
    required this.onCategoryTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header baris + tombol hapus
            Row(
              children: [
                Text('Baris ${index + 1}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGray)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.expense, size: 20),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Catatan
            TextField(
              controller: noteController,
              onChanged: onNoteChanged,
              decoration: _inputDecoration('Catatan'),
              style: const TextStyle(
                  fontSize: 13, color: AppColors.darkBlue),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                // Nominal
                Expanded(
                  child: TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsInputFormatter()],
                    onChanged: onAmountChanged,
                    decoration:
                        _inputDecoration('Nominal').copyWith(prefixText: 'Rp '),
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.darkBlue),
                  ),
                ),
                const SizedBox(width: 8),

                // Kategori
                Expanded(
                  child: GestureDetector(
                    onTap: categoriesLoaded ? onCategoryTap : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.divider),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.categoryId == 0
                                  ? 'Pilih kategori'
                                  : entry.categoryName,
                              style: TextStyle(
                                fontSize: 13,
                                color: entry.categoryId == 0
                                    ? AppColors.darkGray
                                    : AppColors.darkBlue,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down,
                              color: AppColors.darkGray, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle:
          const TextStyle(fontSize: 12, color: AppColors.darkGray),
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide:
            const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _CategoryPickerSheet extends StatelessWidget {
  final List<CategoryModel> categories;
  final int selectedId;
  final ValueChanged<CategoryModel> onSelected;

  const _CategoryPickerSheet({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Pilih Kategori',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBlue)),
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: categories.length,
              itemBuilder: (_, i) {
                final cat = categories[i];
                final isSelected = cat.id == selectedId;
                return ListTile(
                  dense: true,
                  title: Text(cat.name,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.darkBlue,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      )),
                  trailing: isSelected
                      ? const Icon(Icons.check,
                          color: AppColors.primary, size: 18)
                      : null,
                  onTap: () {
                    onSelected(cat);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
