import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/database/daos/history_dao.dart';
import 'report_event.dart';
import 'report_state.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final HistoryDao _dao;

  ReportBloc({HistoryDao? dao})
      : _dao = dao ?? HistoryDao(),
        super(const ReportInitial()) {
    on<ReportLoadSummary>(_onLoadSummary);
    on<ReportLoadByCategory>(_onLoadByCategory);
    on<ReportLoadAsList>(_onLoadAsList);
  }

  List<ReportCategoryItem> _mapRows(
      List<Map<String, dynamic>> rows, String sign) {
    double total = 0;
    for (final row in rows) {
      total += (row['total_amount'] as num?)?.toDouble() ?? 0;
    }
    return rows.map((row) {
      final amt = (row['total_amount'] as num?)?.toDouble() ?? 0;
      return ReportCategoryItem(
        categoryId: (row['category_id'] as int?) ?? 0,
        categoryName: (row['category_name'] as String?) ?? '-',
        categoryIcon: (row['category_icon'] as String?) ?? '',
        categoryColor: (row['category_color'] as String?) ?? '#9e9e9e',
        sign: (row['category_sign'] as String?) ?? sign,
        totalAmount: amt,
        totalCount: (row['total_count'] as int?) ?? 0,
        percentage: total > 0 ? amt / total : 0,
      );
    }).toList();
  }

  Future<void> _onLoadSummary(
      ReportLoadSummary event, Emitter<ReportState> emit) async {
    emit(const ReportLoading());
    try {
      final summary = await _dao.getSummaryByDateRange(event.startDate, event.endDate);
      final incomeRows = await _dao.getReportByCategory(
        startDate: event.startDate,
        endDate: event.endDate,
        sign: '+',
      );
      final expenseRows = await _dao.getReportByCategory(
        startDate: event.startDate,
        endDate: event.endDate,
        sign: '-',
      );
      emit(ReportSummaryLoaded(
        startDate: event.startDate,
        endDate: event.endDate,
        totalIncome: summary['income'] ?? 0,
        totalExpense: summary['expense'] ?? 0,
        incomeItems: _mapRows(incomeRows, '+'),
        expenseItems: _mapRows(expenseRows, '-'),
      ));
    } catch (e) {
      emit(ReportError(e.toString()));
    }
  }

  Future<void> _onLoadByCategory(
      ReportLoadByCategory event, Emitter<ReportState> emit) async {
    emit(const ReportLoading());
    try {
      final rows = await _dao.getReportByCategory(
        startDate: event.startDate,
        endDate: event.endDate,
        sign: event.sign,
      );
      double total = 0;
      for (final row in rows) {
        total += (row['total_amount'] as num?)?.toDouble() ?? 0;
      }
      emit(ReportByCategoryLoaded(
        startDate: event.startDate,
        endDate: event.endDate,
        sign: event.sign,
        items: _mapRows(rows, event.sign),
        total: total,
      ));
    } catch (e) {
      emit(ReportError(e.toString()));
    }
  }

  Future<void> _onLoadAsList(
      ReportLoadAsList event, Emitter<ReportState> emit) async {
    emit(const ReportLoading());
    try {
      final histories = await _dao.getReportAsList(
        startDate: event.startDate,
        endDate: event.endDate,
        categoryId: event.categoryId,
        sign: event.sign,
      );
      double totalIncome = 0;
      double totalExpense = 0;
      for (final h in histories) {
        if (h.isIncome) {
          totalIncome += h.amount;
        } else if (h.isExpense) {
          totalExpense += h.amount;
        }
      }
      emit(ReportAsListLoaded(
        startDate: event.startDate,
        endDate: event.endDate,
        categoryId: event.categoryId,
        sign: event.sign,
        histories: histories,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
      ));
    } catch (e) {
      emit(ReportError(e.toString()));
    }
  }
}
