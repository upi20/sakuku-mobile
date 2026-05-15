import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

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
          Icon(icon, size: 64, color: context.cs.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(
            message,
            style: context.tt.bodyMedium?.copyWith(
              color: context.cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
