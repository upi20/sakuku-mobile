import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/models/category_model.dart';
import '../../../shared/widgets/icon_color_picker_sheet.dart';
import '../bloc/category_bloc.dart';
import '../bloc/category_event.dart';
import '../bloc/category_state.dart';

class AddCategoryPage extends StatelessWidget {
  final String initialSign;
  const AddCategoryPage({super.key, required this.initialSign});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CategoryBloc(),
      child: _AddCategoryBody(initialSign: initialSign),
    );
  }
}

class _AddCategoryBody extends StatefulWidget {
  final String initialSign;
  const _AddCategoryBody({required this.initialSign});

  @override
  State<_AddCategoryBody> createState() => _AddCategoryBodyState();
}

class _AddCategoryBodyState extends State<_AddCategoryBody> {
  final _nameController = TextEditingController();
  late String _sign;
  String _selectedIcon = 'ic_other';
  String _selectedColor = '#2196f3';

  @override
  void initState() {
    super.initState();
    _sign = widget.initialSign;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama kategori tidak boleh kosong')),
      );
      return;
    }
    context.read<CategoryBloc>().add(
          CategoryCreate(
            CategoryModel(
              name: name,
              sign: _sign,
              icon: _selectedIcon,
              color: _selectedColor,
              active: 1,
              editable: 1,
            ),
          ),
        );
  }

  void _showIconColorPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => IconColorPickerSheet(
        selectedIcon: _selectedIcon,
        selectedColor: _selectedColor,
        onSelected: (icon, color) {
          setState(() {
            _selectedIcon = icon;
            _selectedColor = color;
          });
        },
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(
          int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      return const Color(0xFF2b6788);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CategoryBloc, CategoryState>(
      listener: (context, state) {
        if (state is CategorySuccess) {
          context.pop();
        } else if (state is CategoryError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),

            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tambah Kategori'),
          elevation: 0,
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildCategoryCard(),
                    const SizedBox(height: 8),
                    _buildTypeCard(),
                  ],
                ),
              ),
            ),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard() {
    final color = _parseColor(_selectedColor);
    return Container(
      color: context.cs.surfaceContainerLowest,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KATEGORI',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  maxLength: 25,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: 'Nama kategori',
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _showIconColorPicker,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color, width: 1.5),
                  ),
                  child: Icon(AppIcons.fromName(_selectedIcon),
                      color: color, size: 28),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard() {
    return Container(
      color: context.cs.surfaceContainerLowest,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TIPE KATEGORI',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TypeButton(
                  label: 'Pendapatan',
                  selected: _sign == '+',
                  color: AppTheme.income,
                  onTap: () => setState(() => _sign = '+'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TypeButton(
                  label: 'Pengeluaran',
                  selected: _sign == '-',
                  color: AppTheme.expense,
                  onTap: () => setState(() => _sign = '-'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      color: context.cs.surfaceContainerLowest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text(
            'SIMPAN',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(30) : context.cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? color : context.cs.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? color : context.cs.onSurfaceVariant,
              fontWeight:
                  selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
