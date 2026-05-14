import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/history_model.dart';
import '../../../core/repositories/interfaces/i_history_repository.dart';
import '../../../shared/utils/date_formatter.dart';

part 'history_event.dart';
part 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final IHistoryRepository _repository;

  // Navigation position
  String _currentYearMonth = '';
  int _currentYear = DateTime.now().year;
  String _currentDate = DateFormatter.todayString();

  // View mode & filter
  HistoryViewMode _viewMode = HistoryViewMode.monthly;
  Set<int> _selectedAccountIds = {};
  Set<int> _selectedCategoryIds = {};
  String? _customStartDate;
  String? _customEndDate;

  HistoryBloc(this._repository) : super(HistoryInitial()) {
    on<HistoryLoadByMonth>(_onLoadByMonth);
    on<HistoryChangeMonth>(_onChangeMonth);
    on<HistoryChangeYear>(_onChangeYear);
    on<HistoryChangeDay>(_onChangeDay);
    on<HistoryDeleteRequested>(_onDelete);
    on<HistoryRefresh>(_onRefresh);
    on<HistorySetMode>(_onSetMode);
  }

  Future<void> _onLoadByMonth(
    HistoryLoadByMonth event,
    Emitter<HistoryState> emit,
  ) async {
    _viewMode = HistoryViewMode.monthly;
    _selectedAccountIds = {};
    _selectedCategoryIds = {};
    _customStartDate = null;
    _customEndDate = null;
    _currentYearMonth = event.yearMonth;
    _currentYear = int.parse(event.yearMonth.split('-')[0]);
    emit(HistoryLoading());
    await _loadForCurrentMode(emit);
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
    _currentYear = year;
    emit(HistoryLoading());
    await _loadForCurrentMode(emit);
  }

  Future<void> _onChangeYear(
    HistoryChangeYear event,
    Emitter<HistoryState> emit,
  ) async {
    _currentYear += event.delta;
    emit(HistoryLoading());
    await _loadForCurrentMode(emit);
  }

  Future<void> _onChangeDay(
    HistoryChangeDay event,
    Emitter<HistoryState> emit,
  ) async {
    final dt = DateTime.parse(_currentDate)
        .add(Duration(days: event.delta));
    _currentDate =
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    emit(HistoryLoading());
    await _loadForCurrentMode(emit);
  }

  Future<void> _onDelete(
    HistoryDeleteRequested event,
    Emitter<HistoryState> emit,
  ) async {
    await _repository.delete(event.id);
    await _loadForCurrentMode(emit);
  }

  Future<void> _onRefresh(
    HistoryRefresh event,
    Emitter<HistoryState> emit,
  ) async {
    await _loadForCurrentMode(emit);
  }

  Future<void> _onSetMode(
    HistorySetMode event,
    Emitter<HistoryState> emit,
  ) async {
    _viewMode = event.viewMode;
    _selectedAccountIds = Set.from(event.selectedAccountIds);
    _selectedCategoryIds = Set.from(event.selectedCategoryIds);
    _customStartDate = event.customStartDate;
    _customEndDate = event.customEndDate;
    // Reset daily position to today when switching to daily mode
    if (_viewMode == HistoryViewMode.daily) {
      _currentDate = DateFormatter.todayString();
    }
    emit(HistoryLoading());
    await _loadForCurrentMode(emit);
  }

  Future<void> _loadForCurrentMode(Emitter<HistoryState> emit) async {
    try {
      List<HistoryModel> raw;
      String displayLabel;

      switch (_viewMode) {
        case HistoryViewMode.monthly:
          raw = await _repository.getByMonth(_currentYearMonth);
          displayLabel = DateFormatter.formatYearMonth(_currentYearMonth);
          break;
        case HistoryViewMode.yearly:
          raw = await _repository.getByDateRange(
            '$_currentYear-01-01',
            '$_currentYear-12-31',
          );
          displayLabel = 'Tahun $_currentYear';
          break;
        case HistoryViewMode.daily:
          raw = await _repository.getByDateRange(_currentDate, _currentDate);
          final dt = DateTime.parse(_currentDate);
          displayLabel =
              '${dt.day} ${DateFormatter.monthName(dt.month)} ${dt.year}';
          break;
        case HistoryViewMode.all:
          raw = await _repository.filter();
          displayLabel = 'Semua Transaksi';
          break;
        case HistoryViewMode.custom:
          if (_customStartDate != null && _customEndDate != null) {
            raw = await _repository.getByDateRange(
                _customStartDate!, _customEndDate!);
            displayLabel =
                '${DateFormatter.formatDate(_customStartDate!)} – ${DateFormatter.formatDate(_customEndDate!)}';
          } else {
            raw = [];
            displayLabel = 'Filter Kustom';
          }
          break;
      }

      final filtered = _applyInMemoryFilter(raw);
      final summary = _computeSummary(filtered);
      final rows = _buildRows(filtered);

      emit(HistoryLoaded(
        rows: rows,
        summary: summary,
        yearMonth: _currentYearMonth,
        displayLabel: displayLabel,
        viewMode: _viewMode,
        currentYear: _currentYear,
        currentDate: _currentDate,
        selectedAccountIds: Set.from(_selectedAccountIds),
        selectedCategoryIds: Set.from(_selectedCategoryIds),
      ));
    } catch (e) {
      emit(HistoryError(e.toString()));
    }
  }

  List<HistoryModel> _applyInMemoryFilter(List<HistoryModel> items) {
    var result = items;
    if (_selectedAccountIds.isNotEmpty) {
      result = result
          .where((i) => _selectedAccountIds.contains(i.accountId))
          .toList();
    }
    if (_selectedCategoryIds.isNotEmpty) {
      result = result
          .where((i) => _selectedCategoryIds.contains(i.categoryId))
          .toList();
    }
    return result;
  }

  Map<String, double> _computeSummary(List<HistoryModel> items) {
    double income = 0, expense = 0;
    for (final item in items) {
      if (item.isIncome) {
        income += item.amount;
      } else {
        expense += item.amount;
      }
    }
    return {
      'income': income,
      'expense': expense,
      'total': income - expense,
    };
  }

  List<HistoryListRow> _buildRows(List<HistoryModel> items) {
    final rows = <HistoryListRow>[];
    String? lastDate;

    for (final item in items) {
      if (item.date != lastDate) {
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
          date: parts[2],
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
