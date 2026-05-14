import '../../models/history_model.dart';

abstract class IHistoryRepository {
  Future<List<HistoryModel>> getByMonth(String yearMonth);
  Future<List<HistoryModel>> getByDateRange(String start, String end);
  Future<List<HistoryModel>> getByAccount(int accountId);
  Future<List<HistoryModel>> search(String query);
  Future<List<HistoryModel>> filter({
    String? startDate,
    String? endDate,
    int? accountId,
    int? categoryId,
    String? sign,
  });
  Future<HistoryModel?> getById(int id);
  Future<Map<String, double>> getSummaryByMonth(String yearMonth);
  Future<int> create(HistoryModel history);
  Future<int> update(HistoryModel history);
  Future<int> delete(int id);
  Future<List<Map<String, dynamic>>> getReportByCategory({
    required String startDate,
    required String endDate,
    String? sign,
  });
}
