import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('eventcrew.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);
    return await openDatabase(path, version: 4, onCreate: _createDB, onUpgrade: _onUpgrade);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE acara (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_acara TEXT NOT NULL,
        tanggal TEXT NOT NULL,
        budget_total INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'Persiapan'
      )
    ''');

    await db.execute('''
      CREATE TABLE divisi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_acara INTEGER NOT NULL,
        nama_divisi TEXT NOT NULL,
        alokasi_budget INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'Belum Aktif'
      )
    ''');

    await db.execute('''
      CREATE TABLE task (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_divisi INTEGER NOT NULL,
        nama_task TEXT NOT NULL,
        is_done INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'Belum Selesai',
        deadline TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE pengeluaran (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_divisi INTEGER NOT NULL,
        nama_item TEXT NOT NULL,
        nominal INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Add 'status' column to 'acara' table when upgrading from version 1 -> 2
    if (oldVersion < 2) {
      try {
        await db.execute("ALTER TABLE acara ADD COLUMN status TEXT NOT NULL DEFAULT 'Persiapan'");
      } catch (e) {
        // ignore if column already exists or any issue; we don't want to break existing DB
      }
    }
    // Add 'status' column to 'divisi' table when upgrading to version 3
    if (oldVersion < 3) {
      try {
        await db.execute("ALTER TABLE divisi ADD COLUMN status TEXT NOT NULL DEFAULT 'Belum Aktif'");
      } catch (e) {
        // ignore if column already exists or any issue
      }
    }
    // Add 'status' and 'deadline' columns to 'task' table when upgrading to version 4
    if (oldVersion < 4) {
      try {
        await db.execute("ALTER TABLE task ADD COLUMN status TEXT NOT NULL DEFAULT 'Belum Selesai'");
      } catch (e) {}
      try {
        await db.execute("ALTER TABLE task ADD COLUMN deadline TEXT");
      } catch (e) {}
    }
  }

  Future<void> updateDivisiStatus(int id, String statusNew) async {
    final db = await instance.database;
    await db.update('divisi', {'status': statusNew}, where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getAcaraById(int id) async {
    final db = await instance.database;
    final res = await db.query('acara', where: 'id = ?', whereArgs: [id], limit: 1);
    if (res.isEmpty) return null;
    return res.first;
  }

  Future<void> updateAcaraStatus(int id, String status) async {
    final db = await instance.database;
    await db.update('acara', {'status': status}, where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD ACARA ---
  Future<int> insertAcara(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('acara', row);
  }

  Future<List<Map<String, dynamic>>> getSemuaAcara() async {
    final db = await instance.database;
    return await db.query('acara', orderBy: 'id DESC');
  }

  Future<int> deleteAcara(int id) async {
    final db = await instance.database;
    return await db.delete('acara', where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD DIVISI ---
  Future<int> insertDivisi(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('divisi', row);
  }

  Future<List<Map<String, dynamic>>> getDivisiByAcara(int idAcara) async {
    final db = await instance.database;
    return await db.query('divisi', where: 'id_acara = ?', whereArgs: [idAcara]);
  }

  // --- CRUD TASK ---
  Future<int> insertTask(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('task', row);
  }

  Future<List<Map<String, dynamic>>> getTasksByDivisi(int idDivisi) async {
    final db = await instance.database;
    return await db.query('task', where: 'id_divisi = ?', whereArgs: [idDivisi]);
  }

  Future<void> updateTaskStatus(int id, int isDone) async {
    final db = await instance.database;
    final statusText = isDone == 1 ? 'Selesai' : 'Belum Selesai';
    await db.update('task', {'is_done': isDone, 'status': statusText}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteTask(int id) async {
    final db = await instance.database;
    return await db.delete('task', where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD PENGELUARAN ---
  Future<int> insertPengeluaran(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('pengeluaran', row);
  }

  Future<List<Map<String, dynamic>>> getPengeluaranByDivisi(int idDivisi) async {
    final db = await instance.database;
    return await db.query('pengeluaran', where: 'id_divisi = ?', whereArgs: [idDivisi]);
  }

  /// Delete a division and its related tasks and pengeluaran within a transaction.
  Future<int> deleteDivisi(int id) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      // delete tasks related to divisi
      await txn.delete('task', where: 'id_divisi = ?', whereArgs: [id]);
      // delete pengeluaran related to divisi
      await txn.delete('pengeluaran', where: 'id_divisi = ?', whereArgs: [id]);
      // delete the divisi itself
      return await txn.delete('divisi', where: 'id = ?', whereArgs: [id]);
    });
  }
}