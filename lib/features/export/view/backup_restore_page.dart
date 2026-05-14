import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/widgets/confirm_dialog.dart';

class BackupRestorePage extends StatefulWidget {
  const BackupRestorePage({super.key});

  @override
  State<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends State<BackupRestorePage> {
  bool _loading = false;

  // ── Path helper ──────────────────────────────────────────────

  Future<String> _dbPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, 'MyWallet.db');
  }

  // ── Cadangkan ────────────────────────────────────────────────

  Future<void> _backup() async {
    setState(() => _loading = true);
    try {
      final src = File(await _dbPath());
      if (!src.existsSync()) {
        _snack('File database tidak ditemukan');
        return;
      }

      // Salin ke temp dir lalu share
      final tmp = await getTemporaryDirectory();
      final now = DateTime.now();
      final stamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final dest = File(p.join(tmp.path, 'DompetKu_backup_$stamp.db'));
      await src.copy(dest.path);

      await Share.shareXFiles(
        [XFile(dest.path)],
        text: 'Backup database DompetKu $stamp',
      );
    } catch (e) {
      _snack('Cadangkan gagal: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Pulihkan ─────────────────────────────────────────────────

  Future<void> _restore() async {
    // Pilih file .db
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;

    final pickedPath = result.files.single.path;
    if (pickedPath == null) {
      _snack('File tidak dapat dibaca');
      return;
    }

    // Validasi magic bytes SQLite: "SQLite format 3\0" (16 bytes)
    final picked = File(pickedPath);
    final magic = await picked.openRead(0, 16).expand((e) => e).toList();
    const sqliteMagic = [
      0x53, 0x51, 0x4C, 0x69, 0x74, 0x65, 0x20, 0x66,
      0x6F, 0x72, 0x6D, 0x61, 0x74, 0x20, 0x33, 0x00,
    ];
    final isValid = magic.length == 16 &&
        List.generate(16, (i) => magic[i] == sqliteMagic[i]).every((v) => v);

    if (!isValid) {
      _snack('File bukan database SQLite yang valid');
      return;
    }

    if (!mounted) return;

    // Konfirmasi
    ConfirmDialog.show(
      context,
      title: 'Pulihkan Data',
      message:
          'Semua data saat ini akan ditimpa dengan data dari file backup. '
          'Aplikasi akan ditutup otomatis setelah pemulihan selesai.\n\n'
          'Lanjutkan?',
      confirmLabel: 'Pulihkan',
      onConfirm: () => _doRestore(picked),
    );
  }

  Future<void> _doRestore(File src) async {
    setState(() => _loading = true);
    try {
      final dbPath = await _dbPath();

      // Tutup koneksi database
      await AppDatabase.instance.close();

      // Timpa file database
      await src.copy(dbPath);

      _snack('Berhasil dipulihkan. Menutup aplikasi...');

      // Beri waktu snackbar tampil, lalu force exit agar DB reinit saat buka ulang
      await Future.delayed(const Duration(seconds: 2));
      exit(0);
    } catch (e) {
      _snack('Pemulihan gagal: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── UI ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Backup & Restore'),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Cadangkan database secara rutin agar data tidak hilang. '
                          'File backup berformat .db dan dapat dipulihkan kapan saja.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primary.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Cadangkan
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  child: ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.income.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.backup_outlined,
                          color: AppColors.income),
                    ),
                    title: const Text('Cadangkan',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkBlue)),
                    subtitle: const Text(
                      'Ekspor file .db ke penyimpanan / share',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.darkGray),
                    ),
                    trailing: const Icon(Icons.chevron_right,
                        color: AppColors.darkGray),
                    onTap: _backup,
                  ),
                ),
                const SizedBox(height: 12),

                // Pulihkan
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  child: ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.expense.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.restore_outlined,
                          color: AppColors.expense),
                    ),
                    title: const Text('Pulihkan',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkBlue)),
                    subtitle: const Text(
                      'Pilih file .db backup untuk memulihkan data',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.darkGray),
                    ),
                    trailing: const Icon(Icons.chevron_right,
                        color: AppColors.darkGray),
                    onTap: _restore,
                  ),
                ),
                const SizedBox(height: 24),

                // Peringatan
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.expense.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.expense.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_outlined,
                          color: AppColors.expense.withValues(alpha: 0.8),
                          size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Memulihkan data akan menimpa seluruh data saat ini '
                          'dan tidak dapat dibatalkan.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.expense.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
