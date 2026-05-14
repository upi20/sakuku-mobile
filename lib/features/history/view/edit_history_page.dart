import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/account_model.dart';
import '../../../core/models/category_model.dart';
import '../../../core/repositories/interfaces/i_history_repository.dart';
import '../../../shared/utils/date_formatter.dart';
import '../../../shared/widgets/colored_icon.dart';
import '../bloc/add_history_bloc.dart';
import '../bloc/history_bloc.dart';

class EditHistoryPage extends StatefulWidget {
  final int historyId;
  const EditHistoryPage({super.key, required this.historyId});

  @override
  State<EditHistoryPage> createState() => _EditHistoryPageState();
}

class _EditHistoryPageState extends State<EditHistoryPage> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _loadAndInit();
  }

  Future<void> _loadAndInit() async {
    final repo = context.read<IHistoryRepository>();
    final item = await repo.getById(widget.historyId);
    if (item == null || !mounted) return;
    _amountController.text = item.amount.toStringAsFixed(0);
    _noteController.text = item.note;
    context.read<AddHistoryBloc>().add(AddHistoryEditInit(item));
    setState(() => _initialized = true);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddHistoryBloc, AddHistoryState>(
      listener: (context, state) {
        if (state is AddHistorySuccess) {
          context.read<HistoryBloc>().add(HistoryRefresh());
          context.pop();
        } else if (state is AddHistoryError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            title: const Text('Edit Transaksi',
                style: TextStyle(color: Colors.white)),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: state is AddHistoryReady && _initialized
              ? _buildForm(context, state)
              : const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Widget _buildForm(BuildContext context, AddHistoryReady state) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _TypeToggle(sign: state.sign),
                _PickerCard(
                  label: 'KATEGORI',
                  hint: 'Pilih Kategori',
                  selectedName: state.selectedCategory?.name,
                  iconName: state.selectedCategory?.icon,
                  iconColor: state.selectedCategory != null
                      ? ColoredIcon.parseColor(state.selectedCategory!.color)
                      : Colors.grey,
                  onTap: () => _pickCategory(context, state),
                ),
                _PickerCard(
                  label: 'REKENING',
                  hint: 'Pilih Rekening',
                  selectedName: state.selectedAccount?.name,
                  iconName: state.selectedAccount?.icon,
                  iconColor: state.selectedAccount != null
                      ? ColoredIcon.parseColor(state.selectedAccount!.color)
                      : Colors.grey,
                  onTap: () => _pickAccount(context, state),
                ),
                _AmountField(controller: _amountController),
                const SizedBox(height: 8),
                _NoteField(controller: _noteController),
                const SizedBox(height: 8),
                _DateTimeCard(date: state.date, time: state.time),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
        _SaveButton(
          onPressed: () {
            context.read<AddHistoryBloc>()
              ..add(AddHistoryAmountChanged(_amountController.text))
              ..add(AddHistoryNoteChanged(_noteController.text))
              ..add(AddHistorySubmit());
          },
        ),
      ],
    );
  }

  void _pickCategory(BuildContext context, AddHistoryReady state) async {
    final bloc = context.read<AddHistoryBloc>();
    final picked = await showModalBottomSheet<CategoryModel>(
      context: context,
      builder: (_) => _CategoryPicker(categories: state.categories),
    );
    if (picked != null && mounted) {
      bloc.add(AddHistoryCategorySelected(picked));
    }
  }

  void _pickAccount(BuildContext context, AddHistoryReady state) async {
    final bloc = context.read<AddHistoryBloc>();
    final picked = await showModalBottomSheet<AccountModel>(
      context: context,
      builder: (_) => _AccountPicker(accounts: state.accounts),
    );
    if (picked != null && mounted) {
      bloc.add(AddHistoryAccountSelected(picked));
    }
  }
}

// ------- Reusable form sub-widgets -------

class _TypeToggle extends StatelessWidget {
  final String sign;
  const _TypeToggle({required this.sign});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _ToggleBtn(
              label: 'Pemasukan',
              selected: sign == '+',
              selectedColor: AppColors.income,
              onTap: () => context
                  .read<AddHistoryBloc>()
                  .add(AddHistoryTypeChanged('+')),
            ),
          ),
          Expanded(
            child: _ToggleBtn(
              label: 'Pengeluaran',
              selected: sign == '-',
              selectedColor: AppColors.expense,
              onTap: () => context
                  .read<AddHistoryBloc>()
                  .add(AddHistoryTypeChanged('-')),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? selectedColor : Colors.transparent,
          border: Border.all(color: selectedColor),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : selectedColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _PickerCard extends StatelessWidget {
  final String label;
  final String hint;
  final String? selectedName;
  final String? iconName;
  final Color iconColor;
  final VoidCallback onTap;

  const _PickerCard({
    required this.label,
    required this.hint,
    required this.selectedName,
    required this.iconName,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBlue,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedName ?? hint,
                      style: TextStyle(
                        color: selectedName != null
                            ? AppColors.darkBlue
                            : AppColors.disabled,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (iconName != null)
                    ColoredIcon(
                        iconName: iconName!,
                        backgroundColor: iconColor,
                        size: 36,
                        iconSize: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  const _AmountField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'JUMLAH',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBlue,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 19,
            decoration: InputDecoration(
              hintText: '0',
              counterText: '',
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.darkBlue,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteField extends StatelessWidget {
  final TextEditingController controller;
  const _NoteField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.multiline,
        maxLines: null,
        maxLength: 500,
        decoration: InputDecoration(
          hintText: 'Tambah catatan...',
          counterText: '',
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _DateTimeCard extends StatelessWidget {
  final DateTime date;
  final TimeOfDay time;
  const _DateTimeCard({required this.date, required this.time});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormatter.formatDate(
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}');
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _DateTimeBtn(
              icon: Icons.date_range,
              label: dateStr,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null && context.mounted) {
                  context
                      .read<AddHistoryBloc>()
                      .add(AddHistoryDateChanged(picked));
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          _DateTimeBtn(
            icon: Icons.access_time,
            label: timeStr,
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: time,
              );
              if (picked != null && context.mounted) {
                context
                    .read<AddHistoryBloc>()
                    .add(AddHistoryTimeChanged(picked));
              }
            },
          ),
        ],
      ),
    );
  }
}

class _DateTimeBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DateTimeBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: AppColors.darkBlue),
      label: Text(label,
          style: const TextStyle(color: AppColors.darkBlue, fontSize: 13)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _SaveButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Simpan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  final List<CategoryModel> categories;
  const _CategoryPicker({required this.categories});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Pilih Kategori',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.darkBlue)),
        ),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: categories.length,
            itemBuilder: (_, i) {
              final cat = categories[i];
              final bg = ColoredIcon.parseColor(cat.color);
              return ListTile(
                leading: ColoredIcon(
                    iconName: cat.icon,
                    backgroundColor: bg,
                    size: 40,
                    iconSize: 22),
                title: Text(cat.name,
                    style: const TextStyle(color: AppColors.darkBlue)),
                onTap: () => Navigator.of(context).pop(cat),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _AccountPicker extends StatelessWidget {
  final List<AccountModel> accounts;
  const _AccountPicker({required this.accounts});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Pilih Rekening',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.darkBlue)),
        ),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: accounts.length,
            itemBuilder: (_, i) {
              final acc = accounts[i];
              final bg = ColoredIcon.parseColor(acc.color);
              return ListTile(
                leading: ColoredIcon(
                    iconName: acc.icon,
                    backgroundColor: bg,
                    size: 40,
                    iconSize: 22),
                title: Text(acc.name,
                    style: const TextStyle(color: AppColors.darkBlue)),
                onTap: () => Navigator.of(context).pop(acc),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
