import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../bloc/theme_cubit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _shareApp(BuildContext context) async {
    await Share.shareUri(Uri.parse('https://play.google.com/store/apps'));
  }

  Future<void> _openStoreListing() async {
    final uri = Uri.parse('https://play.google.com/store/apps');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ── Tampilan ──────────────────────────────────────────────────
          _SectionHeader(label: 'Tampilan'),
          _ThemeToggleTile(),

          // ── Kelola Data ───────────────────────────────────────────────
          _SectionHeader(label: 'Kelola Data'),
          _SettingsTile(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Rekening',
            onTap: () => context.push('/settings/account'),
          ),
          _SettingsTile(
            icon: Icons.category_outlined,
            label: 'Kategori',
            onTap: () => context.push('/settings/category'),
          ),
          _SettingsTile(
            icon: Icons.balance_outlined,
            label: 'Balancing',
            onTap: () => context.push('/settings/balancing'),
          ),

          // ── Keamanan ──────────────────────────────────────────────────
          _SectionHeader(label: 'Keamanan'),
          _SettingsTile(
            icon: Icons.pin_outlined,
            label: 'PIN',
            onTap: () => context.push('/settings/pin'),
          ),

          // ── Data ──────────────────────────────────────────────────────
          _SectionHeader(label: 'Data'),
          _SettingsTile(
            icon: Icons.upload_file_outlined,
            label: 'Ekspor Excel',
            onTap: () => context.push('/settings/export'),
          ),
          _SettingsTile(
            icon: Icons.backup_outlined,
            label: 'Backup & Restore',
            onTap: () => context.push('/settings/backup'),
          ),

          // ── Lainnya ───────────────────────────────────────────────────
          _SectionHeader(label: 'Lainnya'),
          _SettingsTile(
            icon: Icons.share_outlined,
            label: 'Bagikan Aplikasi',
            onTap: () => _shareApp(context),
          ),
          _SettingsTile(
            icon: Icons.star_outline,
            label: 'Beri Penilaian',
            onTap: _openStoreListing,
          ),
          _SettingsTile(
            icon: Icons.info_outline,
            label: 'Info Aplikasi',
            onTap: () => context.push('/settings/info'),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Dark mode toggle ──────────────────────────────────────────────────────────

class _ThemeToggleTile extends StatelessWidget {
  const _ThemeToggleTile();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, mode) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Terang'),
                icon: Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('Sistem'),
                icon: Icon(Icons.brightness_auto_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Gelap'),
                icon: Icon(Icons.dark_mode_outlined),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (s) =>
                context.read<ThemeCubit>().setTheme(s.first),
          ),
        );
      },
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: context.tt.labelSmall?.copyWith(
          color: context.cs.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

// ── Settings tile ─────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
