import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../../models/category_model.dart';

class CategoryDao {
  final _db = AppDatabase.instance;

  Future<List<CategoryModel>> getAll({bool activeOnly = true}) async {
    final db = await _db.database;
    final where = activeOnly ? 'category_active = 1' : null;
    final maps = await db.query(
      'Category',
      where: where,
      orderBy: 'category_name ASC',
    );
    return maps.map(CategoryModel.fromMap).toList();
  }

  Future<List<CategoryModel>> getBySign(String sign,
      {bool activeOnly = true}) async {
    final db = await _db.database;
    final whereArgs = activeOnly ? [sign, 1] : [sign];
    final where = activeOnly
        ? 'category_sign = ? AND category_active = ?'
        : 'category_sign = ?';
    final maps = await db.query(
      'Category',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'category_name ASC',
    );
    return maps.map(CategoryModel.fromMap).toList();
  }

  Future<CategoryModel?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query(
      'Category',
      where: 'category_id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isNotEmpty ? CategoryModel.fromMap(maps.first) : null;
  }

  Future<int> insert(CategoryModel category) async {
    final db = await _db.database;
    return db.insert('Category', category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> update(CategoryModel category) async {
    final db = await _db.database;
    return db.update(
      'Category',
      category.toMap(),
      where: 'category_id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> softDelete(int id) async {
    final db = await _db.database;
    return db.update(
      'Category',
      {'category_active': 0},
      where: 'category_id = ?',
      whereArgs: [id],
    );
  }
}
