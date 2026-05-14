import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../../models/history_model.dart';

class HistoryDao {
  final _db = AppDatabase.instance;

  static const String _joinQuery = '''
    SELECT h.*,
      c.category_name, c.category_icon, c.category_color,
      a.account_name, a.account_icon, a.account_color
    FROM History h
    LEFT JOIN Category c ON h.history_category_id = c.category_id
    LEFT JOIN Account a ON h.history_account_id = a.account_id
  ''';

  Future<List<HistoryModel>> getByMonth(String yearMonth) async {
    final db = await _db.database;
    final maps = await db.rawQuery(
      '$_joinQuery WHERE h.history_date LIKE ? ORDER BY h.history_date_time DESC',
      ['$yearMonth%'],
    );
    return maps.map(HistoryModel.fromMap).toList();
  }

  Future<List<HistoryModel>> getByDateRange(
      String startDate, String endDate) async {
    final db = await _db.database;
    final maps = await db.rawQuery(
      '$_joinQuery WHERE h.history_date >= ? AND h.history_date <= ? ORDER BY h.history_date_time DESC',
      [startDate, endDate],
    );
    return maps.map(HistoryModel.fromMap).toList();
  }

  Future<List<HistoryModel>> getByAccount(int accountId) async {
    final db = await _db.database;
    final maps = await db.rawQuery(
      '$_joinQuery WHERE h.history_account_id = ? ORDER BY h.history_date_time DESC',
      [accountId],
    );
    return maps.map(HistoryModel.fromMap).toList();
  }

  Future<List<HistoryModel>> search(String query) async {
    final db = await _db.database;
    final maps = await db.rawQuery(
      '$_joinQuery WHERE h.history_note LIKE ? OR c.category_name LIKE ? OR a.account_name LIKE ? ORDER BY h.history_date_time DESC',
      ['%$query%', '%$query%', '%$query%'],
    );
    return maps.map(HistoryModel.fromMap).toList();
  }

  Future<List<HistoryModel>> filter({
    String? startDate,
    String? endDate,
    int? accountId,
    int? categoryId,
    String? sign,
  }) async {
    final db = await _db.database;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (startDate != null) {
      conditions.add('h.history_date >= ?');
      args.add(startDate);
    }
    if (endDate != null) {
      conditions.add('h.history_date <= ?');
      args.add(endDate);
    }
    if (accountId != null) {
      conditions.add('h.history_account_id = ?');
      args.add(accountId);
    }
    if (categoryId != null) {
      conditions.add('h.history_category_id = ?');
      args.add(categoryId);
    }
    if (sign != null) {
      conditions.add('h.history_sign = ?');
      args.add(sign);
    }

    final where =
        conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';
    final maps = await db.rawQuery(
      '$_joinQuery $where ORDER BY h.history_date_time DESC',
      args,
    );
    return maps.map(HistoryModel.fromMap).toList();
  }

  Future<HistoryModel?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.rawQuery(
      '$_joinQuery WHERE h.history_id = ? LIMIT 1',
      [id],
    );
    return maps.isNotEmpty ? HistoryModel.fromMap(maps.first) : null;
  }

  Future<Map<String, double>> getSummaryByMonth(String yearMonth) async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(CASE WHEN history_sign = '+' AND history_type != 3 THEN history_amount ELSE 0 END), 0) as income,
        COALESCE(SUM(CASE WHEN history_sign = '-' AND history_type != 3 THEN history_amount ELSE 0 END), 0) as expense
      FROM History
      WHERE history_date LIKE ?
    ''', ['$yearMonth%']);
    return {
      'income': (result.first['income'] as num?)?.toDouble() ?? 0.0,
      'expense': (result.first['expense'] as num?)?.toDouble() ?? 0.0,
    };
  }

  Future<int> insert(HistoryModel history) async {
    final db = await _db.database;
    return db.insert('History', history.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> update(HistoryModel history) async {
    final db = await _db.database;
    return db.update(
      'History',
      history.toMap(),
      where: 'history_id = ?',
      whereArgs: [history.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return db.delete('History', where: 'history_id = ?', whereArgs: [id]);
  }

  Future<HistoryModel?> getFeeByTransferId(int transferId) async {
    final db = await _db.database;
    final maps = await db.rawQuery(
      '$_joinQuery WHERE h.history_transfer_id = ? AND h.history_type = 4 LIMIT 1',
      [transferId],
    );
    return maps.isNotEmpty ? HistoryModel.fromMap(maps.first) : null;
  }

  Future<int> deleteByTransferId(int transferId) async {
    final db = await _db.database;
    return db.delete('History',
        where: 'history_transfer_id = ?', whereArgs: [transferId]);
  }

  Future<List<Map<String, dynamic>>> getReportByCategory({
    required String startDate,
    required String endDate,
    String? sign,
  }) async {
    final db = await _db.database;
    final signFilter = sign != null ? 'AND h.history_sign = ?' : '';
    final args = sign != null
        ? [startDate, endDate, sign]
        : [startDate, endDate];
    return db.rawQuery('''
      SELECT 
        c.category_id, c.category_name, c.category_icon, c.category_color, c.category_sign,
        SUM(h.history_amount) as total_amount,
        COUNT(h.history_id) as total_count
      FROM History h
      LEFT JOIN Category c ON h.history_category_id = c.category_id
      WHERE h.history_date >= ? AND h.history_date <= ? $signFilter
        AND h.history_type != 3
      GROUP BY c.category_id
      ORDER BY total_amount DESC
    ''', args);
  }
}
