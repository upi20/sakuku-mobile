import 'package:equatable/equatable.dart';
import '../../../core/models/history_model.dart';

abstract class ReportState extends Equatable {
  const ReportState();
  @override
  List<Object?> get props => [];
}

class ReportInitial extends ReportState {
  const ReportInitial();
}

class ReportLoading extends ReportState {
  const ReportLoading();
}

/// State laporan ringkasan — untuk halaman utama ReportPage
class ReportSummaryLoaded extends ReportState {
  final String startDate;
  final String endDate;
  final double totalIncome;
  final double totalExpense;
  final List<ReportCategoryItem> incomeItems;
  final List<ReportCategoryItem> expenseItems;

  const ReportSummaryLoaded({
    required this.startDate,
    required this.endDate,
    required this.totalIncome,
    required this.totalExpense,
    required this.incomeItems,
    required this.expenseItems,
  });

  @override
  List<Object?> get props =>
      [startDate, endDate, totalIncome, totalExpense, incomeItems, expenseItems];
}

/// State laporan per kategori — untuk ReportByCategoryPage
class ReportByCategoryLoaded extends ReportState {
  final String startDate;
  final String endDate;
  final String sign;
  final List<ReportCategoryItem> items;
  final double total;

  const ReportByCategoryLoaded({
    required this.startDate,
    required this.endDate,
    required this.sign,
    required this.items,
    required this.total,
  });

  @override
  List<Object?> get props => [startDate, endDate, sign, items, total];
}

/// State laporan sebagai list transaksi
class ReportAsListLoaded extends ReportState {
  final String startDate;
  final String endDate;
  final int? categoryId;
  final String? sign;
  final List<HistoryModel> histories;
  final double totalIncome;
  final double totalExpense;

  const ReportAsListLoaded({
    required this.startDate,
    required this.endDate,
    this.categoryId,
    this.sign,
    required this.histories,
    required this.totalIncome,
    required this.totalExpense,
  });

  @override
  List<Object?> get props =>
      [startDate, endDate, categoryId, sign, histories, totalIncome, totalExpense];
}

class ReportError extends ReportState {
  final String message;
  const ReportError(this.message);
  @override
  List<Object?> get props => [message];
}

/// Model item laporan per kategori
class ReportCategoryItem extends Equatable {
  final int categoryId;
  final String categoryName;
  final String categoryIcon;
  final String categoryColor;
  final String sign;
  final double totalAmount;
  final int totalCount;
  final double percentage;

  const ReportCategoryItem({
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.sign,
    required this.totalAmount,
    required this.totalCount,
    required this.percentage,
  });

  @override
  List<Object?> get props => [categoryId, totalAmount];
}
