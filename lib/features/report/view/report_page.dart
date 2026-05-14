import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Laporan',
          style: TextStyle(color: AppColors.darkBlue),
        ),
      ),
    );
  }
}
