part of 'history_bloc.dart';

enum HistoryViewMode { all, daily, monthly, yearly, custom }

/// A row in the grouped history list.
sealed class HistoryListRow {}

class HistoryDateHeaderRow extends HistoryListRow {
  final String date;       // e.g. "15"
  final String dayName;    // e.g. "Senin"
  final String monthYear;  // e.g. "Januari 2024"
  final double total;      // net sum for the day (income - expense)

  HistoryDateHeaderRow({
    required this.date,
    required this.dayName,
    required this.monthYear,
    required this.total,
  });
}

class HistoryTransactionRow extends HistoryListRow {
  final HistoryModel item;
  HistoryTransactionRow(this.item);
}

abstract class HistoryState {}

class HistoryInitial extends HistoryState {}

class HistoryLoading extends HistoryState {}

class HistoryLoaded extends HistoryState {
  final List<HistoryListRow> rows;
  final Map<String, double> summary;
  final String yearMonth;
  final String displayLabel;      // e.g. "Mei 2026", "Tahun 2026", "14 Mei 2026"
  final HistoryViewMode viewMode;
  final int currentYear;
  final String currentDate;        // "yyyy-MM-dd", used in daily mode
  final Set<int> selectedAccountIds;  // empty = all accounts
  final Set<int> selectedCategoryIds; // empty = all categories

  HistoryLoaded({
    required this.rows,
    required this.summary,
    required this.yearMonth,
    required this.displayLabel,
    required this.viewMode,
    required this.currentYear,
    this.currentDate = '',
    this.selectedAccountIds = const {},
    this.selectedCategoryIds = const {},
  });
}

class HistoryError extends HistoryState {
  final String message;
  HistoryError(this.message);
}
