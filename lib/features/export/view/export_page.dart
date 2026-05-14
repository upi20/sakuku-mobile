import 'dart:io';

import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/database/daos/history_dao.dart';
import '../../../core/models/history_model.dart';
import '../../../shared/utils/currency_formatter.dart';

enum _ExportFormat { excel, csv }

enum _ExportRange { thisMonth, last3Months, thisYear, custom }

class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  final _dao = HistoryDao();

  _ExportFormat _format = _ExportFormat.excel;
  _ExportRange _range = _ExportRange.thisMonth;

  DateTime _customStart = DateTime.now().copyWith(day: 1);
  DateTime _customEnd = DateTime.now();

  bool _loading = false;

  // ── Date helpers ──────────────────────────────────────────────

  ({String start, String end}) _getDateRange() {
    final now = DateTime.now();
    switch (_range) {
      case _ExportRange.thisMonth:
        final s = DateTime(now.year, now.month, 1);
        return (start: _fmt(s), end: _fmt(now));
      case _ExportRange.last3Months:
        final s = DateTime(now.year, now.month - 2, 1);
        return (start: _fmt(s), end: _fmt(now));
      case _ExportRange.thisYear:
        final s = DateTime(now.year, 1, 1);
        return (start: _fmt(s), end: _fmt(now));
      case _ExportRange.custom:
        return (start: _fmt(_customStart), end: _fmt(_customEnd));
    }
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── Export ───────────────────────────────────────────────────

  Future<void> _doExport() async {
    setState(() => _loading = true);
    try {
      final range = _getDateRange();
      final rows = await _dao.getByDateRange(range.start, range.end);
      if (rows.isEmpty) {
        _showSnack('Tidak ada data pada rentang waktu tersebut');
        return;
      }
      final file = _format == _ExportFormat.excel
          ? await _buildExcel(rows, range.start, range.end)
          : await _buildCsv(rows, range.start, range.end);
      await Share.shareXFiles([XFile(file.path)],
          text: 'Ekspor riwayat transaksi DompetKu');
    } catch (e) {
      _showSnack('Gagal ekspor: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<File> _buildExcel(
      List<HistoryModel> rows, String start, String end) async {
    final excel = Excel.createExcel();
    final sheet = excel['Riwayat'];

    // Header row
    final headers = [
      'Tanggal', 'Waktu', 'Jenis', 'Kategori',
      'Rekening', 'Jumlah', 'Tanda', 'Catatan',
    ];
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(bold: true);
    }

    // Data rows
    for (var r = 0; r < rows.length; r++) {
      final h = rows[r];
      final rowData = [
        h.date,
        h.time,
        _typeLabel(h.type),
        h.categoryName ?? '',
        h.accountName ?? '',
        h.amount.toStringAsFixed(0),
        h.sign,
        h.note,
      ];
      for (var c = 0; c < rowData.length; c++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1))
            .value = TextCellValue(rowData[c]);
      }
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/dompetku_${start}_${end}.xlsx';
    final bytes = excel.encode();
    if (bytes == null) throw Exception('Gagal encode file Excel');
    final file = File(path);
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<File> _buildCsv(
      List<HistoryModel> rows, String start, String end) async {
    final buf = StringBuffer();
    buf.writeln('Tanggal,Waktu,Jenis,Kategori,Rekening,Jumlah,Tanda,Catatan');
    for (final h in rows) {
      final note = h.note.replaceAll('"', '""');
      buf.writeln(
        '"${h.date}","${h.time}","${_typeLabel(h.type)}","${h.categoryName ?? ''}","${h.accountName ?? ''}","${h.amount.toStringAsFixed(0)}","${h.sign}","$note"',
      );
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/dompetku_${start}_${end}.csv';
    final file = File(path);
    await file.writeAsString(buf.toString());
    return file;
  }

  String _typeLabel(int type) {
    switch (type) {
      case 1:
        return 'Pemasukan';
      case 2:
        return 'Pengeluaran';
      case 3:
        return 'Transfer';
      case 4:
        return 'Hutang/Piutang';
      case 5:
        return 'Cicilan Hutang';
      default:
        return 'Lainnya';
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Date picker ──────────────────────────────────────────────

  Future<void> _pickCustomDate(bool isStart) async {
    final init = isStart ? _customStart : _customEnd;
    final first = DateTime(2020);
    final last = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: init.isBefore(first) ? first : init,
      firstDate: first,
      lastDate: last,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _customStart = picked;
        if (_customEnd.isBefore(_customStart)) _customEnd = _customStart;
      } else {
        _customEnd = picked;
        if (_customStart.isAfter(_customEnd)) _customStart = _customEnd;
      }
    });
  }

  // ── UI ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Ekspor Data'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Format
          _SectionLabel(label: 'Format File'),
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                RadioListTile<_ExportFormat>(
                  value: _ExportFormat.excel,
                  groupValue: _format,
                  onChanged: (v) => setState(() => _format = v!),
                  title: const Text('Excel (.xlsx)',
                      style: TextStyle(color: AppColors.darkBlue)),
                  subtitle: const Text('Buka dengan Microsoft Excel / Google Sheets',
                      style: TextStyle(fontSize: 12, color: AppColors.darkGray)),
                  activeColor: AppColors.primary,
                ),
                const Divider(height: 1, indent: 16),
                RadioListTile<_ExportFormat>(
                  value: _ExportFormat.csv,
                  groupValue: _format,
                  onChanged: (v) => setState(() => _format = v!),
                  title: const Text('CSV (.csv)',
                      style: TextStyle(color: AppColors.darkBlue)),
                  subtitle: const Text('Kompatibel dengan semua spreadsheet',
                      style: TextStyle(fontSize: 12, color: AppColors.darkGray)),
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Rentang waktu
          _SectionLabel(label: 'Rentang Waktu'),
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                ..._ExportRange.values.map((r) {
                  return Column(
                    children: [
                      RadioListTile<_ExportRange>(
                        value: r,
                        groupValue: _range,
                        onChanged: (v) => setState(() => _range = v!),
                        title: Text(_rangeLabel(r),
                            style: const TextStyle(color: AppColors.darkBlue)),
                        activeColor: AppColors.primary,
                      ),
                      if (r != _ExportRange.values.last)
                        const Divider(height: 1, indent: 16),
                    ],
                  );
                }),
              ],
            ),
          ),

          // Custom date picker
          if (_range == _ExportRange.custom) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateButton(
                    label: 'Dari',
                    value: _fmt(_customStart),
                    onTap: () => _pickCustomDate(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateButton(
                    label: 'Sampai',
                    value: _fmt(_customEnd),
                    onTap: () => _pickCustomDate(false),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _doExport,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.file_download_outlined),
              label:
                  Text(_loading ? 'Sedang mengekspor...' : 'Ekspor & Bagikan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _rangeLabel(_ExportRange r) {
    switch (r) {
      case _ExportRange.thisMonth:
        return 'Bulan Ini';
      case _ExportRange.last3Months:
        return '3 Bulan Terakhir';
      case _ExportRange.thisYear:
        return 'Tahun Ini';
      case _ExportRange.custom:
        return 'Sesuaikan';
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.darkGray,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.darkGray)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBlue)),
          ],
        ),
      ),
    );
  }
}

// Suppress unused import warning — CurrencyFormatter imported for future use
// ignore: unused_import
final _unused = CurrencyFormatter;
