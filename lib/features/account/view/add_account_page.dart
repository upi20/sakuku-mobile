import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/models/account_model.dart';
import '../../../shared/utils/thousands_formatter.dart';
import '../../../shared/widgets/icon_color_picker_sheet.dart';
import '../bloc/account_bloc.dart';
import '../bloc/account_event.dart';
import '../bloc/account_state.dart';

class AddAccountPage extends StatelessWidget {
  const AddAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AccountBloc(),
      child: const _AddAccountBody(),
    );
  }
}

class _AddAccountBody extends StatefulWidget {
  const _AddAccountBody();

  @override
  State<_AddAccountBody> createState() => _AddAccountBodyState();
}

class _AddAccountBodyState extends State<_AddAccountBody> {
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

  void _submit() {
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
    return BlocListener<AccountBloc, AccountState>(
      listener: (context, state) {
        if (state is AccountSuccess) {
          context.pop();
        } else if (state is AccountError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
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
                    _buildInitialCard(context),
                  ],
                ),
              ),
            ),
            // Bottom save button
            _buildSaveButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context) {
    final color = _parseColor(_selectedColor, context.cs.primary);
    return Container(
      color: context.cs.surfaceContainerLowest,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REKENING',
            style: context.tt.labelSmall?.copyWith(
              color: context.cs.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  maxLength: 25,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: 'Nama rekening',
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Icon + color picker button
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

  Widget _buildInitialCard(BuildContext context) {
    return Container(
      color: context.cs.surfaceContainerLowest,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SALDO AWAL',
            style: context.tt.labelSmall?.copyWith(
              color: context.cs.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Rp',
                  style: context.tt.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _initialController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsInputFormatter()],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: '0',
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
      color: context.cs.surfaceContainerLowest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _submit,
          child: const Text('SIMPAN'),
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

  Color _parseColor(String hex, Color fallback) {
    try {
      final cleaned = hex.replaceFirst('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return fallback;
    }
  }
}
