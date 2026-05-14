import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../../models/account_model.dart';

class AccountDao {
  final _db = AppDatabase.instance;

  Future<List<AccountModel>> getAll({bool activeOnly = true}) async {
    final db = await _db.database;
    final where = activeOnly ? 'account_active = 1' : null;
    final maps = await db.query(
      'Account',
      where: where,
      orderBy: 'account_name ASC',
    );
    return maps.map(AccountModel.fromMap).toList();
  }

  Future<AccountModel?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query(
      'Account',
      where: 'account_id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isNotEmpty ? AccountModel.fromMap(maps.first) : null;
  }

  Future<int> insert(AccountModel account) async {
    final db = await _db.database;
    return db.insert('Account', account.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> update(AccountModel account) async {
    final db = await _db.database;
    return db.update(
      'Account',
      account.toMap(),
      where: 'account_id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> softDelete(int id) async {
    final db = await _db.database;
    return db.update(
      'Account',
      {'account_active': 0},
      where: 'account_id = ?',
      whereArgs: [id],
    );
  }

  Future<int> hardDelete(int id) async {
    final db = await _db.database;
    return db.delete('Account', where: 'account_id = ?', whereArgs: [id]);
  }

  Future<double> getBalance(int accountId) async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(CASE WHEN history_sign = '+' THEN history_amount ELSE 0 END), 0) -
        COALESCE(SUM(CASE WHEN history_sign = '-' THEN history_amount ELSE 0 END), 0) as balance
      FROM History
      WHERE history_account_id = ?
    ''', [accountId]);
    return (result.first['balance'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<int, double>> getAllBalances() async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT 
        history_account_id,
        COALESCE(SUM(CASE WHEN history_sign = '+' THEN history_amount ELSE 0 END), 0) -
        COALESCE(SUM(CASE WHEN history_sign = '-' THEN history_amount ELSE 0 END), 0) as balance
      FROM History
      GROUP BY history_account_id
    ''');
    return {
      for (final row in result)
        row['history_account_id'] as int:
            (row['balance'] as num?)?.toDouble() ?? 0.0
    };
  }
}
