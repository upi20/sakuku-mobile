import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../../models/debt_trans_model.dart';

class DebtTransDao {
  final _db = AppDatabase.instance;

  Future<List<DebtTransModel>> getByDebtId(int debtId) async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT dt.*, a.account_name, d.debt_name
      FROM DebtTrans dt
      LEFT JOIN Account a ON dt.debt_trans_account_id = a.account_id
      LEFT JOIN Debt d ON dt.debt_trans_debt_id = d.debt_id
      WHERE dt.debt_trans_debt_id = ?
      ORDER BY dt.debt_trans_date_time DESC
    ''', [debtId]);
    return maps.map(DebtTransModel.fromMap).toList();
  }

  Future<int> insert(DebtTransModel trans) async {
    final db = await _db.database;
    return db.insert('DebtTrans', trans.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> update(DebtTransModel trans) async {
    final db = await _db.database;
    return db.update(
      'DebtTrans',
      trans.toMap(),
      where: 'debt_trans_id = ?',
      whereArgs: [trans.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return db.delete('DebtTrans',
        where: 'debt_trans_id = ?', whereArgs: [id]);
  }
}
