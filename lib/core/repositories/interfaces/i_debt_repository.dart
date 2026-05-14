import '../../models/debt_model.dart';
import '../../models/debt_trans_model.dart';

abstract class IDebtRepository {
  Future<List<DebtModel>> getAll({int? type, bool? isRelief});
  Future<DebtModel?> getById(int id);
  Future<int> createDebt(DebtModel debt);
  Future<int> updateDebt(DebtModel debt);
  Future<int> deleteDebt(int id);
  Future<List<DebtTransModel>> getTransactions(int debtId);
  Future<int> createTransaction(DebtTransModel trans);
  Future<int> updateTransaction(DebtTransModel trans);
  Future<int> deleteTransaction(int id);
}
