import '../../database/daos/history_dao.dart';
import '../../models/history_model.dart';
import '../interfaces/i_history_repository.dart';

class HistoryRepository implements IHistoryRepository {
  final HistoryDao _dao;

  HistoryRepository({HistoryDao? dao}) : _dao = dao ?? HistoryDao();

  @override
  Future<List<HistoryModel>> getByMonth(String yearMonth) =>
      _dao.getByMonth(yearMonth);

  @override
  Future<List<HistoryModel>> getByDateRange(String start, String end) =>
      _dao.getByDateRange(start, end);

  @override
  Future<List<HistoryModel>> getByAccount(int accountId) =>
      _dao.getByAccount(accountId);

  @override
  Future<List<HistoryModel>> search(String query) => _dao.search(query);

  @override
  Future<List<HistoryModel>> filter({
    String? startDate,
    String? endDate,
    int? accountId,
    int? categoryId,
    String? sign,
  }) =>
      _dao.filter(
        startDate: startDate,
        endDate: endDate,
        accountId: accountId,
        categoryId: categoryId,
        sign: sign,
      );

  @override
  Future<HistoryModel?> getById(int id) => _dao.getById(id);

  @override
  Future<Map<String, double>> getSummaryByMonth(String yearMonth) =>
      _dao.getSummaryByMonth(yearMonth);

  @override
  Future<int> create(HistoryModel history) => _dao.insert(history);

  @override
  Future<int> update(HistoryModel history) => _dao.update(history);

  @override
  Future<int> delete(int id) => _dao.delete(id);

  @override
  Future<List<Map<String, dynamic>>> getReportByCategory({
    required String startDate,
    required String endDate,
    String? sign,
  }) =>
      _dao.getReportByCategory(
          startDate: startDate, endDate: endDate, sign: sign);
}
