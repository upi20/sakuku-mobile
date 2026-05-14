part of 'history_bloc.dart';

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
  final String yearMonth; // e.g. "2024-01"
  final String displayMonth; // e.g. "Januari 2024"

  HistoryLoaded({
    required this.rows,
    required this.summary,
    required this.yearMonth,
    required this.displayMonth,
  });
}

class HistoryError extends HistoryState {
  final String message;
  HistoryError(this.message);
}
