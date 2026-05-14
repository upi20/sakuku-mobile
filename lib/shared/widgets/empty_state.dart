import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Centered empty state with icon and message.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.darkGray),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.darkGray,
            ),
          ),
        ],
      ),
    );
  }
}
