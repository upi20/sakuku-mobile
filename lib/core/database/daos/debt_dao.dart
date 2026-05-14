import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../../models/debt_model.dart';

class DebtDao {
  final _db = AppDatabase.instance;

  static const String _innerQuery = '''
    SELECT d.*,
      a.account_name, a.account_icon, a.account_color,
      COALESCE(
        (SELECT SUM(dt.debt_trans_amount) FROM DebtTrans dt WHERE dt.debt_trans_debt_id = d.debt_id),
        0
      ) as paid_amount
    FROM Debt d
    LEFT JOIN Account a ON d.debt_account_id = a.account_id
  ''';

  static const String _joinQuery = _innerQuery;

  Future<List<DebtModel>> getAll({int? type, bool? isRelief}) async {
    final db = await _db.database;
    final innerConditions = <String>[];
    final args = <dynamic>[];

    if (type != null) {
      innerConditions.add('d.debt_type = ?');
      args.add(type);
    }

    final innerWhere = innerConditions.isNotEmpty
        ? 'WHERE ${innerConditions.join(' AND ')}'
        : '';

    String outerWhere = '';
    if (isRelief == true) {
      outerWhere = 'WHERE paid_amount >= debt_amount';
    } else if (isRelief == false) {
      outerWhere = 'WHERE paid_amount < debt_amount';
    }

    final maps = await db.rawQuery(
      '''SELECT * FROM ($_innerQuery $innerWhere) $outerWhere
         ORDER BY debt_start_date_time DESC''',
      args,
    );
    return maps.map(DebtModel.fromMap).toList();
  }

  Future<DebtModel?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.rawQuery(
      '$_joinQuery WHERE d.debt_id = ? LIMIT 1',
      [id],
    );
    return maps.isNotEmpty ? DebtModel.fromMap(maps.first) : null;
  }

  Future<int> insert(DebtModel debt) async {
    final db = await _db.database;
    return db.insert('Debt', debt.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> update(DebtModel debt) async {
    final db = await _db.database;
    return db.update(
      'Debt',
      debt.toMap(),
      where: 'debt_id = ?',
      whereArgs: [debt.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return db.delete('Debt', where: 'debt_id = ?', whereArgs: [id]);
  }
}
