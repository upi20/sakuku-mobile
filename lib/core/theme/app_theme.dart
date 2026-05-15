import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pusat semua definisi tema Material Design 3.
/// Semua warna UI diambil dari [ColorScheme] yang di-generate otomatis
/// dari seedColor. Warna semantik (income, expense, transfer) didefinisikan
/// di sini dan bersifat konstanta (tidak bergantung mode).
class AppTheme {
  AppTheme._();

  // ── Seed color (brand) ───────────────────────────────────────────────────
  static const Color seedColor = Color(0xFF2b6788);

  // ── Semantic / domain colors ──────────────────────────────────────────────
  // Warna ini tetap sama di light & dark — digunakan untuk makna keuangan.
  static const Color income   = Color(0xFF2E7D32); // Material Green 800
  static const Color expense  = Color(0xFFC62828); // Material Red 800
  static const Color transfer = Color(0xFFE65100); // Material Deep Orange 900
  static const Color dueDate  = Color(0xFFC62828);
  static const Color balanced = Color(0xFF1565C0); // M Blue 800

  // ── Light theme ───────────────────────────────────────────────────────────
  static ThemeData light() {
    final cs = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );
    return _buildTheme(cs);
  }

  // ── Dark theme ────────────────────────────────────────────────────────────
  static ThemeData dark() {
    final cs = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );
    return _buildTheme(cs);
  }

  // ── Internal builder ──────────────────────────────────────────────────────
  static ThemeData _buildTheme(ColorScheme cs) {
    final base = cs.brightness == Brightness.dark
        ? ThemeData.dark()
        : ThemeData.light();
    final tt = GoogleFonts.robotoTextTheme(base.textTheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      textTheme: tt,

      // ── AppBar ─────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 3,
        surfaceTintColor: cs.surfaceTint,
        centerTitle: false,
        titleTextStyle: tt.titleLarge?.copyWith(
          color: cs.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        iconTheme: IconThemeData(color: cs.onSurface),
        actionsIconTheme: IconThemeData(color: cs.onSurface),
      ),

      // ── Scaffold ───────────────────────────────────────────────────
      scaffoldBackgroundColor: cs.surface,

      // ── NavigationBar ──────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cs.surfaceContainer,
        indicatorColor: cs.primaryContainer,
        elevation: 3,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? cs.onPrimaryContainer
                : cs.onSurfaceVariant,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return tt.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? cs.onSurface
                : cs.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          );
        }),
      ),

      // ── Card ───────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: cs.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: cs.outlineVariant, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── FAB ────────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
        elevation: 3,
        shape: const CircleBorder(),
      ),

      // ── FilledButton ───────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      // ── OutlinedButton ─────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // ── TextButton ─────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // ── Input ──────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.error, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: cs.onSurfaceVariant),
        hintStyle: TextStyle(
            color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
      ),

      // ── Divider ────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: cs.outlineVariant,
        thickness: 0.5,
        space: 0,
      ),

      // ── ListTile ───────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        titleTextStyle: tt.bodyLarge?.copyWith(color: cs.onSurface),
        subtitleTextStyle:
            tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        iconColor: cs.onSurfaceVariant,
      ),

      // ── Chip ───────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: cs.surfaceContainerHighest,
        selectedColor: cs.primaryContainer,
        labelStyle: tt.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // ── SnackBar ───────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cs.inverseSurface,
        contentTextStyle:
            tt.bodyMedium?.copyWith(color: cs.onInverseSurface),
        actionTextColor: cs.inversePrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // ── BottomSheet ────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surfaceContainerLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        showDragHandle: true,
      ),

      // ── Dialog ─────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: cs.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: tt.titleLarge?.copyWith(color: cs.onSurface),
        contentTextStyle: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
      ),

      // ── Switch ─────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? cs.primary : null),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? cs.primaryContainer
                : null),
      ),
    );
  }
}

// ── BuildContext Extensions ─────────────────────────────────────────────────
/// Shorthand helpers agar tidak perlu menulis `Theme.of(context).colorScheme`
/// di setiap widget.
extension ThemeX on BuildContext {
  ColorScheme get cs => Theme.of(this).colorScheme;
  TextTheme get tt => Theme.of(this).textTheme;
  ThemeData get theme => Theme.of(this);
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
