import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Pengaturan'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          _SettingsItem(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Rekening',
            onTap: () => context.push('/settings/account'),
          ),
          _SettingsItem(
            icon: Icons.category_outlined,
            label: 'Kategori',
            onTap: () => context.push('/settings/category'),
          ),
          const SizedBox(height: 8),
          _SettingsItem(
            icon: Icons.pin_outlined,
            label: 'PIN',
            onTap: null, // Phase 6
          ),
          _SettingsItem(
            icon: Icons.upload_file_outlined,
            label: 'Export',
            onTap: null, // Phase 7
          ),
          _SettingsItem(
            icon: Icons.backup_outlined,
            label: 'Backup',
            onTap: null, // Phase 7
          ),
          const SizedBox(height: 8),
          _SettingsItem(
            icon: Icons.star_outline,
            label: 'Beri Nilai',
            onTap: null,
          ),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primarySoft, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.darkBlue,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.darkBlue),
          ],
        ),
      ),
    );
  }
}

