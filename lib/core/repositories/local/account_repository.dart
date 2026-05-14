import '../../database/daos/account_dao.dart';
import '../../models/account_model.dart';
import '../interfaces/i_account_repository.dart';

class AccountRepository implements IAccountRepository {
  final AccountDao _dao;

  AccountRepository({AccountDao? dao}) : _dao = dao ?? AccountDao();

  @override
  Future<List<AccountModel>> getAll({bool activeOnly = true}) =>
      _dao.getAll(activeOnly: activeOnly);

  @override
  Future<AccountModel?> getById(int id) => _dao.getById(id);

  @override
  Future<int> create(AccountModel account) => _dao.insert(account);

  @override
  Future<int> update(AccountModel account) => _dao.update(account);

  @override
  Future<int> delete(int id) => _dao.softDelete(id);

  @override
  Future<double> getBalance(int accountId) => _dao.getBalance(accountId);

  @override
  Future<Map<int, double>> getAllBalances() => _dao.getAllBalances();
}
