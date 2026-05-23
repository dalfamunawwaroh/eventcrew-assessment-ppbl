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
    return await openDatabase(path, version: 6, onCreate: _createDB, onUpgrade: _onUpgrade);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE acara (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_acara TEXT NOT NULL,
        tanggal_acara TEXT NOT NULL,
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
        divisi_id INTEGER NOT NULL,
        tanggal TEXT NOT NULL,
        nama_barang TEXT NOT NULL,
        jumlah INTEGER NOT NULL,
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
    // Rename 'tanggal' to 'tanggal_acara' when upgrading to version 5
    if (oldVersion < 5) {
      try {
        await db.execute("ALTER TABLE acara RENAME COLUMN tanggal TO tanggal_acara");
      } catch (e) {
        // Fallback for older SQLite versions that don't support RENAME COLUMN
        try {
          await db.execute("ALTER TABLE acara ADD COLUMN tanggal_acara TEXT DEFAULT ''");
          await db.execute("UPDATE acara SET tanggal_acara = tanggal");
        } catch (e2) {}
      }
    }
    // Update pengeluaran table schema when upgrading to version 6
    if (oldVersion < 6) {
      try { await db.execute("ALTER TABLE pengeluaran RENAME COLUMN id_divisi TO divisi_id"); } catch (_) {}
      try { await db.execute("ALTER TABLE pengeluaran RENAME COLUMN nama_item TO nama_barang"); } catch (_) {}
      try { await db.execute("ALTER TABLE pengeluaran ADD COLUMN tanggal TEXT NOT NULL DEFAULT ''"); } catch (_) {}
      try { await db.execute("ALTER TABLE pengeluaran ADD COLUMN jumlah INTEGER NOT NULL DEFAULT 1"); } catch (_) {}
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

  /// Update deadline tugas dengan validasi agar tidak melewati tanggal acara.
  ///
  /// Mengembalikan `true` jika update berhasil, `false` jika `newDeadline`
  /// melewati tanggal acara. Jika data task/divisi/acara tidak ditemukan,
  /// maka akan melempar Exception.
  Future<bool> updateTaskDeadline(int taskId, String newDeadline) async {
    final db = await instance.database;
    return await db.transaction<bool>((txn) async {
      final taskRows = await txn.query('task', where: 'id = ?', whereArgs: [taskId], limit: 1);
      if (taskRows.isEmpty) throw Exception('Task tidak ditemukan');
      final task = taskRows.first;

      final divisiRows = await txn.query('divisi', where: 'id = ?', whereArgs: [task['id_divisi']], limit: 1);
      if (divisiRows.isEmpty) throw Exception('Divisi tidak ditemukan');
      final idAcara = divisiRows.first['id_acara'];

      final acaraRows = await txn.query('acara', where: 'id = ?', whereArgs: [idAcara], limit: 1);
      if (acaraRows.isEmpty) throw Exception('Acara tidak ditemukan');
      
      final tanggalAcaraStr = (acaraRows.first['tanggal_acara'] as String?) ?? (acaraRows.first['tanggal'] as String?) ?? '';
      if (tanggalAcaraStr.isEmpty) throw Exception('Tanggal acara tidak ditemukan');
      final tanggalAcara = tanggalAcaraStr;

      final newDeadlineDate = DateTime.parse(newDeadline);
      final acaraDate = DateTime.parse(tanggalAcara);
      if (newDeadlineDate.isAfter(acaraDate)) {
        return false;
      }

      await txn.update('task', {'deadline': newDeadline}, where: 'id = ?', whereArgs: [taskId]);
      return true;
    });
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

  /// Menyimpan pengeluaran dengan validasi anggaran.
  /// Mengembalikan `true` jika berhasil, `false` jika melebihi alokasi divisi.
  Future<bool> insertPengeluaranWithValidasi({
    required int divisiId,
    required String tanggal,
    required String namaBarang,
    required int jumlah,
    required int nominal,
  }) async {
    final db = await instance.database;
    return await db.transaction<bool>((txn) async {
      // 1. Ambil alokasi divisi
      final divisiRows = await txn.query('divisi', where: 'id = ?', whereArgs: [divisiId], limit: 1);
      if (divisiRows.isEmpty) throw Exception('Divisi tidak ditemukan');
      final alokasi = (divisiRows.first['alokasi_budget'] as num).toInt();

      // 2. Hitung total pengeluaran saat ini untuk divisi ini
      final totalRows = await txn.rawQuery(
        'SELECT SUM(jumlah * nominal) as total FROM pengeluaran WHERE divisi_id = ?',
        [divisiId],
      );
      final totalSaatIni = totalRows.isNotEmpty && totalRows.first['total'] != null
          ? (totalRows.first['total'] as num).toInt()
          : 0;

      // 3. Validasi: total saat ini + pengeluaran baru > alokasi?
      final totalBaru = totalSaatIni + (jumlah * nominal);
      if (alokasi > 0 && totalBaru > alokasi) {
        return false; // Over budget!
      }

      // 4. Aman, lakukan insert
      await txn.insert('pengeluaran', {
        'divisi_id': divisiId,
        'tanggal': tanggal,
        'nama_barang': namaBarang,
        'jumlah': jumlah,
        'nominal': nominal,
      });
      return true;
    });
  }

  /// Memperbarui pengeluaran dengan validasi anggaran.
  /// Mengembalikan `true` jika berhasil, `false` jika melebihi alokasi divisi.
  Future<bool> updatePengeluaranWithValidasi({
    required int id,
    required int divisiId,
    required String tanggal,
    required String namaBarang,
    required int jumlah,
    required int nominal,
  }) async {
    final db = await instance.database;
    return await db.transaction<bool>((txn) async {
      // 1. Ambil alokasi divisi
      final divisiRows = await txn.query('divisi', where: 'id = ?', whereArgs: [divisiId], limit: 1);
      if (divisiRows.isEmpty) throw Exception('Divisi tidak ditemukan');
      final alokasi = (divisiRows.first['alokasi_budget'] as num).toInt();

      // 2. Hitung total pengeluaran SELAIN item yang sedang diedit
      final totalRows = await txn.rawQuery(
        'SELECT SUM(jumlah * nominal) as total FROM pengeluaran WHERE divisi_id = ? AND id != ?',
        [divisiId, id],
      );
      final totalSelainIni = totalRows.isNotEmpty && totalRows.first['total'] != null
          ? (totalRows.first['total'] as num).toInt()
          : 0;

      // 3. Validasi: total selain item ini + nilai baru > alokasi?
      final totalBaru = totalSelainIni + (jumlah * nominal);
      if (alokasi > 0 && totalBaru > alokasi) {
        return false; // Over budget!
      }

      // 4. Aman, lakukan update
      await txn.update('pengeluaran', {
        'tanggal': tanggal,
        'nama_barang': namaBarang,
        'jumlah': jumlah,
        'nominal': nominal,
      }, where: 'id = ?', whereArgs: [id]);
      return true;
    });
  }

  Future<List<Map<String, dynamic>>> getPengeluaranByDivisi(int divisiId) async {
    final db = await instance.database;
    return await db.query('pengeluaran', where: 'divisi_id = ?', whereArgs: [divisiId]);
  }

  Future<int> getTotalPengeluaranByDivisi(int divisiId) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(jumlah * nominal) as total FROM pengeluaran WHERE divisi_id = ?',
      [divisiId],
    );
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toInt();
    }
    return 0;
  }

  /// Menghitung TOTAL SEMUA pengeluaran dari seluruh divisi dalam satu acara.
  /// Menggunakan INNER JOIN antara tabel pengeluaran dan divisi.
  Future<int> getGrandTotalPengeluaranByAcara(int acaraId) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      '''SELECT SUM(p.jumlah * p.nominal) as grand_total
         FROM pengeluaran p
         INNER JOIN divisi d ON p.divisi_id = d.id
         WHERE d.id_acara = ?''',
      [acaraId],
    );
    if (result.isNotEmpty && result.first['grand_total'] != null) {
      return (result.first['grand_total'] as num).toInt();
    }
    return 0;
  }

  Future<int> updatePengeluaran(int id, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.update('pengeluaran', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deletePengeluaran(int id) async {
    final db = await instance.database;
    return await db.delete('pengeluaran', where: 'id = ?', whereArgs: [id]);
  }

  /// Delete a division and its related tasks and pengeluaran within a transaction.
  Future<int> deleteDivisi(int id) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      // delete tasks related to divisi
      await txn.delete('task', where: 'id_divisi = ?', whereArgs: [id]);
      // delete pengeluaran related to divisi (handle both old and new schema columns gracefully)
      try {
        await txn.delete('pengeluaran', where: 'divisi_id = ?', whereArgs: [id]);
      } catch (_) {
        await txn.delete('pengeluaran', where: 'id_divisi = ?', whereArgs: [id]);
      }
      // delete the divisi itself
      return await txn.delete('divisi', where: 'id = ?', whereArgs: [id]);
    });
  }
}