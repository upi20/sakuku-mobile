import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/models/category_model.dart';
import '../../../shared/widgets/icon_color_picker_sheet.dart';
import '../bloc/category_bloc.dart';
import '../bloc/category_event.dart';
import '../bloc/category_state.dart';

class EditCategoryPage extends StatelessWidget {
  final int categoryId;
  const EditCategoryPage({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CategoryBloc()..add(const CategoryLoad()),
      child: _EditCategoryBody(categoryId: categoryId),
    );
  }
}

class _EditCategoryBody extends StatefulWidget {
  final int categoryId;
  const _EditCategoryBody({required this.categoryId});

  @override
  State<_EditCategoryBody> createState() => _EditCategoryBodyState();
}

class _EditCategoryBodyState extends State<_EditCategoryBody> {
  final _nameController = TextEditingController();
  CategoryModel? _original;
  String _selectedIcon = 'ic_other';
  String _selectedColor = '#2196f3';
  bool _isActive = true;
  bool _loaded = false;

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
    if (_original == null) return;
    context.read<CategoryBloc>().add(
          CategoryUpdate(
            _original!.copyWith(
              name: name,
              icon: _selectedIcon,
              color: _selectedColor,
              active: _isActive ? 1 : 0,
            ),
          ),
        );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: const Text(
          'Menghapus kategori akan menghapus semua transaksi terkait. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('BATAL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<CategoryBloc>()
                  .add(CategoryDelete(widget.categoryId));
            },
            child: const Text(
              'HAPUS',
              style: TextStyle(color: AppColors.expense),
            ),
          ),
        ],
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
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CategoryBloc, CategoryState>(
      listener: (context, state) {
        if (state is CategoryLoaded && !_loaded) {
          final all = [
            ...state.incomeCategories,
            ...state.expenseCategories,
          ];
          final cat =
              all.where((c) => c.id == widget.categoryId).firstOrNull;
          if (cat != null) {
            setState(() {
              _original = cat;
              _nameController.text = cat.name;
              _selectedIcon = cat.icon;
              _selectedColor = cat.color;
              _isActive = cat.active == 1;
              _loaded = true;
            });
          }
        }
        if (state is CategorySuccess) {
          context.pop();
        } else if (state is CategoryError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.expense,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            title: const Text('Edit Kategori'),
            elevation: 0,
          ),
          body: _original == null
              ? const Center(child: CircularProgressIndicator())
              : _buildForm(),
        );
      },
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildCategoryCard(),
                const SizedBox(height: 8),
                _buildActivationCard(),
                if (_original!.editable == 1) ...[
                  const SizedBox(height: 8),
                  _buildDeleteButton(),
                ],
              ],
            ),
          ),
        ),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildCategoryCard() {
    final color = _parseColor(_selectedColor);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KATEGORI',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBlue,
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
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBlue),
                  decoration: InputDecoration(
                    hintText: 'Nama kategori',
                    counterText: '',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
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

  Widget _buildActivationCard() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AKTIVASI KATEGORI',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBlue,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Kategori nonaktif tidak akan muncul di daftar pilihan transaksi',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.darkGray, height: 1.4),
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: _isActive,
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withAlpha(100),
                onChanged: (val) => setState(() => _isActive = val),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton() {
    return InkWell(
      onTap: _confirmDelete,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.delete_outline, color: AppColors.expense, size: 22),
            SizedBox(width: 6),
            Text(
              'HAPUS KATEGORI',
              style: TextStyle(
                color: AppColors.expense,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
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
