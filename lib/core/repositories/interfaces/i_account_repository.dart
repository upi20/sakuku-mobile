import '../../models/account_model.dart';

abstract class IAccountRepository {
  Future<List<AccountModel>> getAll({bool activeOnly = true});
  Future<AccountModel?> getById(int id);
  Future<int> create(AccountModel account);
  Future<int> update(AccountModel account);
  Future<int> delete(int id);
  Future<double> getBalance(int accountId);
  Future<Map<int, double>> getAllBalances();
}
