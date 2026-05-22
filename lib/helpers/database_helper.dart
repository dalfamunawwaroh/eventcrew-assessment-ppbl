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
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE acara (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_acara TEXT NOT NULL,
        tanggal TEXT NOT NULL,
        budget_total INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE divisi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_acara INTEGER NOT NULL,
        nama_divisi TEXT NOT NULL,
        alokasi_budget INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE task (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_divisi INTEGER NOT NULL,
        nama_task TEXT NOT NULL,
        is_done INTEGER NOT NULL DEFAULT 0
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
    await db.update('task', {'is_done': isDone}, where: 'id = ?', whereArgs: [id]);
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
}