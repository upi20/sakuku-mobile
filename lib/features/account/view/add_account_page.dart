import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/models/account_model.dart';
import '../../../shared/utils/thousands_formatter.dart';
import '../../../shared/widgets/icon_color_picker_sheet.dart';
import '../bloc/account_bloc.dart';
import '../bloc/account_event.dart';
import '../bloc/account_state.dart';

class AddAccountPage extends StatefulWidget {
  const AddAccountPage({super.key});

  @override
  State<AddAccountPage> createState() => _AddAccountPageState();
}

class _AddAccountPageState extends State<AddAccountPage> {
  final _nameController = TextEditingController();
  final _initialController = TextEditingController();

  String _selectedIcon = 'ic_cash';
  String _selectedColor = '#2196f3';

  @override
  void dispose() {
    _nameController.dispose();
    _initialController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama rekening tidak boleh kosong')),
      );
      return;
    }

    final initialRaw = ThousandsInputFormatter.toRaw(_initialController.text);
    final initialAmount = double.tryParse(initialRaw) ?? 0.0;

    context.read<AccountBloc>().add(
          AccountCreate(
            AccountModel(
              name: name,
              icon: _selectedIcon,
              color: _selectedColor,
              active: 1,
            ),
            initialBalance: initialAmount,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AccountBloc(),
      child: BlocListener<AccountBloc, AccountState>(
        listener: (context, state) {
          if (state is AccountSuccess) {
            context.pop();
          } else if (state is AccountError) {
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
            title: const Text('Tambah Rekening'),
            elevation: 0,
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Card: Nama rekening + icon picker
                      _buildAccountCard(context),
                      const SizedBox(height: 8),
                      // Card: Saldo awal
                      _buildInitialCard(),
                    ],
                  ),
                ),
              ),
              // Bottom save button
              _buildSaveButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context) {
    final color = _parseColor(_selectedColor);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'REKENING',
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
                      fontWeight: FontWeight.bold, color: AppColors.darkBlue),
                  decoration: InputDecoration(
                    hintText: 'Nama rekening',
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
              // Icon + color picker button
              GestureDetector(
                onTap: () => _showIconColorPicker(context),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color, width: 1.5),
                  ),
                  child: Icon(
                    AppIcons.fromName(_selectedIcon),
                    color: color,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInitialCard() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SALDO AWAL',
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
              const Text('Rp',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBlue)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _initialController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsInputFormatter()],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: AppColors.darkBlue),
                  decoration: InputDecoration(
                    hintText: '0',
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _submit(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('SIMPAN',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      ),
    );
  }

  void _showIconColorPicker(BuildContext context) {
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
      final cleaned = hex.replaceFirst('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }
}
