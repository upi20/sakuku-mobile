import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Riwayat',
          style: TextStyle(color: AppColors.darkBlue),
        ),
      ),
    );
  }
}
