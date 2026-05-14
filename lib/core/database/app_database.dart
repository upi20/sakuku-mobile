import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final dbPath = join(documentsDir.path, 'MyWallet.db');

    // Copy from assets on first launch
    if (!await File(dbPath).exists()) {
      await _copyDatabaseFromAssets(dbPath);
    }

    return openDatabase(
      dbPath,
      version: 1,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _copyDatabaseFromAssets(String dbPath) async {
    final ByteData data =
        await rootBundle.load('assets/db/MyWallet.db');
    final List<int> bytes = data.buffer.asUint8List();
    await File(dbPath).writeAsBytes(bytes, flush: true);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Reset DB (e.g., for testing)
  Future<void> resetDatabase() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final dbPath = join(documentsDir.path, 'MyWallet.db');
    await close();
    await File(dbPath).delete();
    _database = await _initDatabase();
  }
}
