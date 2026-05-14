import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class DebtPage extends StatelessWidget {
  const DebtPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Hutang',
          style: TextStyle(color: AppColors.darkBlue),
        ),
      ),
    );
  }
}
