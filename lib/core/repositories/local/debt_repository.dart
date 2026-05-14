import '../../database/daos/debt_dao.dart';
import '../../database/daos/debt_trans_dao.dart';
import '../../models/debt_model.dart';
import '../../models/debt_trans_model.dart';
import '../interfaces/i_debt_repository.dart';

class DebtRepository implements IDebtRepository {
  final DebtDao _debtDao;
  final DebtTransDao _transDao;

  DebtRepository({DebtDao? debtDao, DebtTransDao? transDao})
      : _debtDao = debtDao ?? DebtDao(),
        _transDao = transDao ?? DebtTransDao();

  @override
  Future<List<DebtModel>> getAll({int? type, bool? isRelief}) =>
      _debtDao.getAll(type: type, isRelief: isRelief);

  @override
  Future<DebtModel?> getById(int id) => _debtDao.getById(id);

  @override
  Future<int> createDebt(DebtModel debt) => _debtDao.insert(debt);

  @override
  Future<int> updateDebt(DebtModel debt) => _debtDao.update(debt);

  @override
  Future<int> deleteDebt(int id) => _debtDao.delete(id);

  @override
  Future<List<DebtTransModel>> getTransactions(int debtId) =>
      _transDao.getByDebtId(debtId);

  @override
  Future<int> createTransaction(DebtTransModel trans) =>
      _transDao.insert(trans);

  @override
  Future<int> updateTransaction(DebtTransModel trans) =>
      _transDao.update(trans);

  @override
  Future<int> deleteTransaction(int id) => _transDao.delete(id);
}
