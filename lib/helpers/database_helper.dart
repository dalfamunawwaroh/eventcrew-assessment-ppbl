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
    if (oldVersion < 2) {
      try { await db.execute("ALTER TABLE acara ADD COLUMN status TEXT NOT NULL DEFAULT 'Persiapan'"); } catch (_) {}
    }
    if (oldVersion < 3) {
      try { await db.execute("ALTER TABLE divisi ADD COLUMN status TEXT NOT NULL DEFAULT 'Belum Aktif'"); } catch (_) {}
    }
    if (oldVersion < 4) {
      try { await db.execute("ALTER TABLE task ADD COLUMN status TEXT NOT NULL DEFAULT 'Belum Selesai'"); } catch (_) {}
      try { await db.execute("ALTER TABLE task ADD COLUMN deadline TEXT"); } catch (_) {}
    }
    if (oldVersion < 5) {
      try {
        await db.execute("ALTER TABLE acara RENAME COLUMN tanggal TO tanggal_acara");
      } catch (e) {
        try {
          await db.execute("ALTER TABLE acara ADD COLUMN tanggal_acara TEXT DEFAULT ''");
          await db.execute("UPDATE acara SET tanggal_acara = tanggal");
        } catch (_) {}
      }
    }
    if (oldVersion < 6) {
      try { await db.execute("ALTER TABLE pengeluaran RENAME COLUMN id_divisi TO divisi_id"); } catch (_) {}
      try { await db.execute("ALTER TABLE pengeluaran RENAME COLUMN nama_item TO nama_barang"); } catch (_) {}
      try { await db.execute("ALTER TABLE pengeluaran ADD COLUMN tanggal TEXT NOT NULL DEFAULT ''"); } catch (_) {}
      try { await db.execute("ALTER TABLE pengeluaran ADD COLUMN jumlah INTEGER NOT NULL DEFAULT 1"); } catch (_) {}
    }
  }

  // --- CRUD ACARA ---
  Future<Map<String, dynamic>?> getAcaraById(int id) async {
    final db = await instance.database;
    final res = await db.query('acara', where: 'id = ?', whereArgs: [id], limit: 1);
    if (res.isEmpty) return null;
    return res.first;
  }

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

  Future<void> updateAcaraStatus(int id, String status) async {
    final db = await instance.database;
    await db.update('acara', {'status': status}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateAcara(int id, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.update('acara', data, where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD DIVISI ---
  Future<int> insertDivisi(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('divisi', row);
  }

  Future<bool> insertDivisiWithValidasi(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.transaction<bool>((txn) async {
      final idAcara = row['id_acara'];
      final alokasiBaru = row['alokasi_budget'] as int;

      final acaraRows = await txn.query('acara', where: 'id = ?', whereArgs: [idAcara], limit: 1);
      if (acaraRows.isEmpty) return false;
      final budgetAcara = acaraRows.first['budget_total'] as int;

      final sumRows = await txn.rawQuery('SELECT SUM(alokasi_budget) as total FROM divisi WHERE id_acara = ?', [idAcara]);
      int totalTeralokasi = 0;
      if (sumRows.isNotEmpty && sumRows.first['total'] != null) {
        totalTeralokasi = (sumRows.first['total'] as num).toInt();
      }

      if (totalTeralokasi + alokasiBaru > budgetAcara) return false; 

      await txn.insert('divisi', row);
      return true;
    });
  }

  Future<bool> updateDivisiWithValidasi(int idDivisi, int idAcara, String namaDivisi, int alokasiBaru) async {
    final db = await instance.database;
    return await db.transaction<bool>((txn) async {
      final acaraRows = await txn.query('acara', where: 'id = ?', whereArgs: [idAcara], limit: 1);
      if (acaraRows.isEmpty) return false;
      final budgetAcara = acaraRows.first['budget_total'] as int;

      final sumRows = await txn.rawQuery('SELECT SUM(alokasi_budget) as total FROM divisi WHERE id_acara = ? AND id != ?', [idAcara, idDivisi]);
      int totalSelainIni = 0;
      if (sumRows.isNotEmpty && sumRows.first['total'] != null) {
        totalSelainIni = (sumRows.first['total'] as num).toInt();
      }

      if (totalSelainIni + alokasiBaru > budgetAcara) return false;

      await txn.update('divisi', {'nama_divisi': namaDivisi, 'alokasi_budget': alokasiBaru}, where: 'id = ?', whereArgs: [idDivisi]);
      return true;
    });
  }

  Future<List<Map<String, dynamic>>> getDivisiByAcara(int idAcara) async {
    final db = await instance.database;
    return await db.query('divisi', where: 'id_acara = ?', whereArgs: [idAcara]);
  }

  Future<int> deleteDivisi(int id) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      await txn.delete('task', where: 'id_divisi = ?', whereArgs: [id]);
      try {
        await txn.delete('pengeluaran', where: 'divisi_id = ?', whereArgs: [id]);
      } catch (_) {
        await txn.delete('pengeluaran', where: 'id_divisi = ?', whereArgs: [id]);
      }
      return await txn.delete('divisi', where: 'id = ?', whereArgs: [id]);
    });
  }

  // --- AUTOMATISASI STATUS DIVISI BERDASARKAN TUGAS ---
  Future<void> syncDivisiStatus(int idDivisi) async {
    final db = await instance.database;
    final res = await db.rawQuery(
      'SELECT COUNT(*) as total, SUM(CASE WHEN is_done = 1 THEN 1 ELSE 0 END) as done FROM task WHERE id_divisi = ?',
      [idDivisi],
    );
    
    String statusBaru = 'Belum Aktif';
    if (res.isNotEmpty) {
      int total = res.first['total'] as int? ?? 0;
      int done = res.first['done'] as int? ?? 0;

      if (total > 0) {
        if (done == total) {
          statusBaru = 'Selesai';
        } else {
          statusBaru = 'Sedang Bertugas';
        }
      }
    }
    await db.update('divisi', {'status': statusBaru}, where: 'id = ?', whereArgs: [idDivisi]);
  }

  Future<Map<String, int>> getTaskProgressByDivisi(int idDivisi) async {
    final db = await instance.database;
    final res = await db.rawQuery(
      'SELECT COUNT(*) as total, SUM(CASE WHEN is_done = 1 THEN 1 ELSE 0 END) as done FROM task WHERE id_divisi = ?',
      [idDivisi],
    );
    if (res.isNotEmpty) {
      int total = res.first['total'] as int? ?? 0;
      int done = res.first['done'] as int? ?? 0;
      return {'total': total, 'done': done};
    }
    return {'total': 0, 'done': 0};
  }

  // --- CRUD TASK ---
  Future<int> insertTask(Map<String, dynamic> row) async {
    final db = await instance.database;
    int id = await db.insert('task', row); // INSERT INTO task VALUES (...)
    await syncDivisiStatus(row['id_divisi']); // Auto update status
    return id;
  }

  // Menampilkan semua tugas berdasarkan id_divisi tertentu
  Future<List<Map<String, dynamic>>> getTasksByDivisi(int idDivisi) async {
    final db = await instance.database;
    return await db.query('task', where: 'id_divisi = ?', whereArgs: [idDivisi]);
  }


  // Update status tugas (is_done) dan otomatis update status divisi
  Future<void> updateTaskStatus(int id, int isDone) async {
    final db = await instance.database;
    final statusText = isDone == 1 ? 'Selesai' : 'Belum Selesai';
     // Konversi angka ke teks untuk kolom status


    await db.update('task', {'is_done': isDone, 'status': statusText}, where: 'id = ?', whereArgs: [id]);
    // Update dua kolom sekaligus: is_done (angka) dan status (teks)

    // Ambil id_divisi untuk auto update status
    final task = await db.query('task', columns: ['id_divisi'], where: 'id = ?', whereArgs: [id]);
    if (task.isNotEmpty) {
      await syncDivisiStatus(task.first['id_divisi'] as int);
      // Setelah centang/uncentang, otomatis update status divisinya
    }
  }

  Future<int> updateTaskDetail(int id, String namaTask, String? deadline) async {
    final db = await instance.database;
    return await db.update('task', {'nama_task': namaTask, 'deadline': deadline}, where: 'id = ?', whereArgs: [id]);
  }
  // UPDATE task SET nama_task=?, deadline=? WHERE id=?
    // deadline boleh null (nullable)

  Future<int> deleteTask(int id) async {
    final db = await instance.database;
    // Ambil id_divisi sebelum dihapus
    final task = await db.query('task', columns: ['id_divisi'], where: 'id = ?', whereArgs: [id]);
    int idDivisi = 0;
    if (task.isNotEmpty) idDivisi = task.first['id_divisi'] as int;
    // Simpan id_divisi SEBELUM dihapus, untuk sync status setelahnya

    int rows = await db.delete('task', where: 'id = ?', whereArgs: [id]); // DELETE FROM task WHERE id = ?
    if (idDivisi != 0) await syncDivisiStatus(idDivisi); // // Setelah hapus, update status divisi secara otomatis
    return rows;
  }

  // --- CRUD PENGELUARAN ---
  Future<int> insertPengeluaran(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('pengeluaran', row); // INSERT biasa tanpa validasi
  }

  Future<bool> insertPengeluaranWithValidasi({
    required int divisiId, required String tanggal, required String namaBarang, required int jumlah, required int nominal,
  }) async {
    final db = await instance.database;
    return await db.transaction<bool>((txn) async {
      final divisiRows = await txn.query('divisi', where: 'id = ?', whereArgs: [divisiId], limit: 1);
      if (divisiRows.isEmpty) throw Exception('Divisi tidak ditemukan');
      final alokasi = (divisiRows.first['alokasi_budget'] as num).toInt();
       // Ambil batas alokasi budget divisi ini

      final totalRows = await txn.rawQuery('SELECT SUM(jumlah * nominal) as total FROM pengeluaran WHERE divisi_id = ?', [divisiId]);
      final totalSaatIni = totalRows.isNotEmpty && totalRows.first['total'] != null ? (totalRows.first['total'] as num).toInt() : 0;
      // Hitung total pengeluaran yang sudah ada di divisi ini


      final totalBaru = totalSaatIni + (jumlah * nominal);
      if (alokasi > 0 && totalBaru > alokasi) return false; 
      // Jika alokasi > 0 (ada batas) DAN total baru melebihi batas → tolak
      // Jika alokasi == 0 → tidak dibatasi, boleh terus


      await txn.insert('pengeluaran', {
        'divisi_id': divisiId, 'tanggal': tanggal, 'nama_barang': namaBarang, 'jumlah': jumlah, 'nominal': nominal,
      });
      return true; //Berhasil disimpan
    });
  }

  Future<bool> updatePengeluaranWithValidasi({
    required int id, required int divisiId, required String tanggal, required String namaBarang, required int jumlah, required int nominal,
  }) async {
    final db = await instance.database;
    return await db.transaction<bool>((txn) async {
      final divisiRows = await txn.query('divisi', where: 'id = ?', whereArgs: [divisiId], limit: 1);
      if (divisiRows.isEmpty) throw Exception('Divisi tidak ditemukan');
      final alokasi = (divisiRows.first['alokasi_budget'] as num).toInt();

      final totalRows = await txn.rawQuery('SELECT SUM(jumlah * nominal) as total FROM pengeluaran WHERE divisi_id = ? AND id != ?', [divisiId, id]); // Hitung semua pengeluaran KECUALI yang sedang diedit
      final totalSelainIni = totalRows.isNotEmpty && totalRows.first['total'] != null ? (totalRows.first['total'] as num).toInt() : 0;

      final totalBaru = totalSelainIni + (jumlah * nominal);
      if (alokasi > 0 && totalBaru > alokasi) return false;  // Validasi

      await txn.update('pengeluaran', {
        'tanggal': tanggal, 'nama_barang': namaBarang, 'jumlah': jumlah, 'nominal': nominal,
      }, where: 'id = ?', whereArgs: [id]);
      return true;
    });
  }

  // READ (Menampilkan semua pengeluaran berdasarkan divisi tertentu)
  Future<List<Map<String, dynamic>>> getPengeluaranByDivisi(int divisiId) async {
    final db = await instance.database;
    return await db.query('pengeluaran', where: 'divisi_id = ?', whereArgs: [divisiId]); 
    // SELECT * FROM pengeluaran WHERE divisi_id = ?
  }

  Future<int> getTotalPengeluaranByDivisi(int divisiId) async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT SUM(jumlah * nominal) as total FROM pengeluaran WHERE divisi_id = ?', [divisiId]);
    // Hitung total: SUM(qty × harga) untuk semua pengeluaran divisi ini

    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toInt();
    }
    return 0; // Jika belum ada pengeluaran, return 
  }

  Future<int> getGrandTotalPengeluaranByAcara(int acaraId) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT SUM(p.jumlah * p.nominal) as grand_total
      FROM pengeluaran p INNER JOIN divisi d ON p.divisi_id = d.id
      WHERE d.id_acara = ?
    ''', [acaraId]);
    // JOIN dua tabel: ambil semua pengeluaran dari semua divisi milik satu acara
    // Hasilnya: total pengeluaran keseluruhan acara

    if (result.isNotEmpty && result.first['grand_total'] != null) {
      return (result.first['grand_total'] as num).toInt();
    }
    return 0;
  }

  Future<int> updatePengeluaran(int id, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.update('pengeluaran', data, where: 'id = ?', whereArgs: [id]);
    // UPDATE pengeluaran SET ... WHERE id = ? (tanpa validasi budget)
  }

  Future<int> deletePengeluaran(int id) async {
    final db = await instance.database;
    return await db.delete('pengeluaran', where: 'id = ?', whereArgs: [id]);
    // DELETE FROM pengeluaran WHERE id = ?
  }
}