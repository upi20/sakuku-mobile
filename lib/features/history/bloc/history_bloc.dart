import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/history_model.dart';
import '../../../core/repositories/interfaces/i_history_repository.dart';
import '../../../shared/utils/date_formatter.dart';

part 'history_event.dart';
part 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final IHistoryRepository _repository;
  String _currentYearMonth = '';

  HistoryBloc(this._repository) : super(HistoryInitial()) {
    on<HistoryLoadByMonth>(_onLoadByMonth);
    on<HistoryChangeMonth>(_onChangeMonth);
    on<HistoryDeleteRequested>(_onDelete);
    on<HistoryRefresh>(_onRefresh);
  }

  Future<void> _onLoadByMonth(
    HistoryLoadByMonth event,
    Emitter<HistoryState> emit,
  ) async {
    _currentYearMonth = event.yearMonth;
    emit(HistoryLoading());
    await _load(emit);
  }

  Future<void> _onChangeMonth(
    HistoryChangeMonth event,
    Emitter<HistoryState> emit,
  ) async {
    final parts = _currentYearMonth.split('-');
    var year = int.parse(parts[0]);
    var month = int.parse(parts[1]);

    month += event.delta;
    if (month > 12) {
      month = 1;
      year++;
    } else if (month < 1) {
      month = 12;
      year--;
    }

    _currentYearMonth = '$year-${month.toString().padLeft(2, '0')}';
    emit(HistoryLoading());
    await _load(emit);
  }

  Future<void> _onDelete(
    HistoryDeleteRequested event,
    Emitter<HistoryState> emit,
  ) async {
    await _repository.delete(event.id);
    await _load(emit);
  }

  Future<void> _onRefresh(
    HistoryRefresh event,
    Emitter<HistoryState> emit,
  ) async {
    await _load(emit);
  }

  Future<void> _load(Emitter<HistoryState> emit) async {
    try {
      final items = await _repository.getByMonth(_currentYearMonth);
      final summary = await _repository.getSummaryByMonth(_currentYearMonth);
      final rows = _buildRows(items);
      final displayMonth = DateFormatter.formatYearMonth(_currentYearMonth);

      emit(HistoryLoaded(
        rows: rows,
        summary: summary,
        yearMonth: _currentYearMonth,
        displayMonth: displayMonth,
      ));
    } catch (e) {
      emit(HistoryError(e.toString()));
    }
  }

  List<HistoryListRow> _buildRows(List<HistoryModel> items) {
    final rows = <HistoryListRow>[];
    String? lastDate;

    for (final item in items) {
      if (item.date != lastDate) {
        // Calculate daily total for this date group
        final dayItems = items.where((i) => i.date == item.date);
        double dailyTotal = 0;
        for (final d in dayItems) {
          dailyTotal += d.isIncome ? d.amount : -d.amount;
        }

        final parts = item.date.split('-');
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        final dt = DateTime(year, month, day);

        rows.add(HistoryDateHeaderRow(
          date: parts[2], // day number string
          dayName: DateFormatter.dayName(dt.weekday),
          monthYear: '${DateFormatter.monthName(month)} $year',
          total: dailyTotal,
        ));

        lastDate = item.date;
      }
      rows.add(HistoryTransactionRow(item));
    }
    return rows;
  }
}
