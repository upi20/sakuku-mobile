import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Info Aplikasi'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // App icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                size: 52,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'DompetKu',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBlue,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Versi 2.0.0',
              style: TextStyle(fontSize: 14, color: AppColors.darkGray),
            ),
            const SizedBox(height: 32),

            // Info card
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 1,
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.person_outline,
                    label: 'Developer',
                    value: 'Isep Lutpi Nur',
                  ),
                  const Divider(height: 1, indent: 56),
                  _InfoRow(
                    icon: Icons.smartphone_outlined,
                    label: 'Platform',
                    value: 'Android & iOS',
                  ),
                  const Divider(height: 1, indent: 56),
                  _InfoRow(
                    icon: Icons.storage_outlined,
                    label: 'Database',
                    value: 'SQLite (Offline First)',
                  ),
                  const Divider(height: 1, indent: 56),
                  _InfoRow(
                    icon: Icons.code_outlined,
                    label: 'Framework',
                    value: 'Flutter',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
            const Text(
              '© 2026 Isep Lutpi Nur\nAll rights reserved.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.darkGray,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.primarySoft),
          const SizedBox(width: 16),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.darkGray,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.darkBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
