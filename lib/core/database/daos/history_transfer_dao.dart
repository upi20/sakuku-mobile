import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../../models/history_transfer_model.dart';

class HistoryTransferDao {
  final _db = AppDatabase.instance;

  static const String _joinQuery = '''
    SELECT ht.*,
      src.account_name as src_account_name,
      src.account_icon as src_account_icon,
      src.account_color as src_account_color,
      dest.account_name as dest_account_name,
      dest.account_icon as dest_account_icon,
      dest.account_color as dest_account_color
    FROM HistoryTransfer ht
    LEFT JOIN Account src ON ht.transfer_src_account_id = src.account_id
    LEFT JOIN Account dest ON ht.transfer_dest_account_id = dest.account_id
  ''';

  Future<List<HistoryTransferModel>> getByMonth(String yearMonth) async {
    final db = await _db.database;
    final maps = await db.rawQuery(
      '$_joinQuery WHERE ht.transfer_date LIKE ? ORDER BY ht.transfer_datetime DESC',
      ['$yearMonth%'],
    );
    return maps.map(HistoryTransferModel.fromMap).toList();
  }

  Future<HistoryTransferModel?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.rawQuery(
      '$_joinQuery WHERE ht.transfer_id = ? LIMIT 1',
      [id],
    );
    return maps.isNotEmpty
        ? HistoryTransferModel.fromMap(maps.first)
        : null;
  }

  Future<int> insert(HistoryTransferModel transfer) async {
    final db = await _db.database;
    return db.insert('HistoryTransfer', transfer.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> update(HistoryTransferModel transfer) async {
    final db = await _db.database;
    return db.update(
      'HistoryTransfer',
      transfer.toMap(),
      where: 'transfer_id = ?',
      whereArgs: [transfer.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return db.delete('HistoryTransfer',
        where: 'transfer_id = ?', whereArgs: [id]);
  }
}
