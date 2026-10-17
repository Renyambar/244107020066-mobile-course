import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Langkah 2 (Pembuka database) — codelab Minggu 5.
///
/// Satu fungsi pembuka dipakai seluruh repository, sehingga skema tabel hanya
/// didefinisikan di satu tempat.
///
/// Catatan platform:
/// * **Android / iOS** — memakai `sqflite` native (`getDatabasesPath()`).
/// * **Web (Chrome)** — `sqflite` tidak punya implementasi web, jadi factory
///   global dipindah ke `databaseFactoryFfiWeb` (SQLite-wasm yang menyimpan
///   data di IndexedDB). Dipakai untuk demo *layout mobile* lewat browser
///   karena di mesin praktikum tidak tersedia emulator Android.
///   Jalankan `dart run sqflite_common_ffi_web:setup` sekali agar
///   `web/sqlite3.wasm` dan `web/sqflite_sw.js` tersedia.
const notesDbName = 'offline_notes.db';

Future<void> _onCreate(Database db, int version) async {
  await db.execute('''
    CREATE TABLE notes(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      body TEXT NOT NULL DEFAULT '',
      updated_at TEXT NOT NULL,
      dirty INTEGER NOT NULL DEFAULT 0
    )
  ''');
  await db.execute('''
    CREATE TABLE cached_posts(
      id INTEGER PRIMARY KEY,
      payload TEXT NOT NULL,
      cached_at TEXT NOT NULL
    )
  ''');
}

Future<Database> openNotesDb() async {
  if (kIsWeb) {
    // Ganti factory default; `openDatabase` di bawah otomatis memakainya.
    databaseFactory = databaseFactoryFfiWeb;
    return openDatabase(notesDbName, version: 1, onCreate: _onCreate);
  }
  final dir = await getDatabasesPath();
  return openDatabase(
    p.join(dir, notesDbName),
    version: 1,
    onCreate: _onCreate,
    // Skema berubah di versi berikutnya? Naikkan `version` dan tangani di
    // `onUpgrade` (jangan hanya menaikkan versi tanpa migrasi).
  );
}
