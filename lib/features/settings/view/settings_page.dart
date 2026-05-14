import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Pengaturan',
          style: TextStyle(color: AppColors.darkBlue),
        ),
      ),
    );
  }
}
