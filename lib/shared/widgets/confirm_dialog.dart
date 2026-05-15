import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Shows an AlertDialog with a title, optional message, and Yes/No actions.
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String? message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;

  const ConfirmDialog({
    super.key,
    required this.title,
    this.message,
    this.confirmLabel = 'Ya',
    this.cancelLabel = 'Batal',
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    String? message,
    String confirmLabel = 'Ya',
    String cancelLabel = 'Batal',
    required VoidCallback onConfirm,
  }) {
    return showDialog(
      context: context,
      builder: (_) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: message != null ? Text(message!) : null,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          child: Text(
            confirmLabel,
            style: TextStyle(color: context.cs.error),
          ),
        ),
      ],
    );
  }
}
