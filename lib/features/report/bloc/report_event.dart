import 'package:equatable/equatable.dart';

enum ReportDateRangeMode { semua, harian, bulanan, tahunan, custom }

abstract class ReportEvent extends Equatable {
  const ReportEvent();
  @override
  List<Object?> get props => [];
}

/// Load laporan ringkasan (summary + data kategori income & expense) untuk halaman utama
class ReportLoadSummary extends ReportEvent {
  final String startDate; // format: 'yyyy-MM-dd'
  final String endDate;   // format: 'yyyy-MM-dd'

  const ReportLoadSummary({required this.startDate, required this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}

/// Load laporan per kategori untuk rentang tanggal tertentu
class ReportLoadByCategory extends ReportEvent {
  final String startDate;
  final String endDate;
  final String sign; // '+' atau '-'

  const ReportLoadByCategory(
      {required this.startDate,
      required this.endDate,
      required this.sign});

  @override
  List<Object?> get props => [startDate, endDate, sign];
}

/// Load laporan sebagai list transaksi
class ReportLoadAsList extends ReportEvent {
  final String startDate;
  final String endDate;
  final int? categoryId; // optional: filter per kategori
  final String? sign; // optional: null=semua, '+'=pemasukan, '-'=pengeluaran

  const ReportLoadAsList(
      {required this.startDate,
      required this.endDate,
      this.categoryId,
      this.sign});

  @override
  List<Object?> get props => [startDate, endDate, categoryId, sign];
}

