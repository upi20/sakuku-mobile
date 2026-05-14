import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _shareApp(BuildContext context) async {
    await Share.share(
      'DompetKu — Aplikasi pencatatan keuangan pribadi. Download sekarang!',
    );
  }

  Future<void> _openStoreListing() async {
    // Ganti dengan link store yang sesuai saat publish
    final uri = Uri.parse('https://play.google.com/store/apps');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

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
          // Kelola Data
          _SectionHeader(label: 'Kelola Data'),
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

          // Keamanan
          _SectionHeader(label: 'Keamanan'),
          _SettingsItem(
            icon: Icons.pin_outlined,
            label: 'PIN',
            onTap: () => context.push('/settings/pin'),
          ),

          // Data
          _SectionHeader(label: 'Data'),
          _SettingsItem(
            icon: Icons.upload_file_outlined,
            label: 'Ekspor Excel',
            onTap: () => context.push('/settings/export'),
          ),
          _SettingsItem(
            icon: Icons.backup_outlined,
            label: 'Backup & Restore',
            onTap: () => context.push('/settings/backup'),
          ),

          // Lainnya
          _SectionHeader(label: 'Lainnya'),
          _SettingsItem(
            icon: Icons.share_outlined,
            label: 'Bagikan Aplikasi',
            onTap: () => _shareApp(context),
          ),
          _SettingsItem(
            icon: Icons.star_outline,
            label: 'Beri Penilaian',
            onTap: _openStoreListing,
          ),
          _SettingsItem(
            icon: Icons.info_outline,
            label: 'Info Aplikasi',
            onTap: () => context.push('/settings/info'),
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

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.darkGray,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

