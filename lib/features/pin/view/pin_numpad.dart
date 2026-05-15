import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Numpad custom 4x3 untuk input PIN.
/// [onKey] dipanggil dengan karakter '0'–'9'.
/// [onDelete] dipanggil saat tombol hapus ditekan.
/// [darkMode] true → teks putih (untuk background gelap), false → teks gelap.
class PinNumpad extends StatelessWidget {
  final void Function(String key) onKey;
  final VoidCallback onDelete;
  final bool darkMode;

  const PinNumpad({
    super.key,
    required this.onKey,
    required this.onDelete,
    this.darkMode = true,
  });

  @override
  Widget build(BuildContext context) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'del'],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: keys.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((k) {
            if (k.isEmpty) return const SizedBox(width: 80, height: 72);
            if (k == 'del') {
              return _NumKey(
                darkMode: darkMode,
                onTap: onDelete,
                child: Icon(
                  Icons.backspace_outlined,
                  color: darkMode
                      ? context.cs.onPrimary.withValues(alpha: 0.85)
                      : context.cs.onSurface.withValues(alpha: 0.85),
                  size: 22,
                ),
              );
            }
            return _NumKey(
              darkMode: darkMode,
              onTap: () => onKey(k),
              child: Text(
                k,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: darkMode ? context.cs.onPrimary : context.cs.onSurface,
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

class _NumKey extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool darkMode;

  const _NumKey({
    required this.child,
    required this.onTap,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    final fg = darkMode ? context.cs.onPrimary : context.cs.onSurface;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        splashColor: fg.withValues(alpha: darkMode ? 0.2 : 0.1),
        highlightColor: Colors.transparent,
        child: SizedBox(
          width: 80,
          height: 72,
          child: Center(child: child),
        ),
      ),
    );
  }
}
