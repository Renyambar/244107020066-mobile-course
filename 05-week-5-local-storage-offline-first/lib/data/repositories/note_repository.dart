import 'package:sqflite/sqflite.dart';

import '../local/db.dart';
import '../local/note.dart';

/// Langkah 3 (Repository sebagai satu-satunya pintu data) — codelab Minggu 5.
///
/// UI **tidak pernah** memanggil SQLite langsung; semua lewat repository ini
/// lalu dibungkus provider Riverpod. Exception platform sengaja dibiarkan naik
/// sehingga provider mengubahnya menjadi `AsyncError`.
class NoteRepository {
  NoteRepository({Future<Database> Function()? openDb})
      : _openDb = openDb ?? openNotesDb;

  /// Diinjeksi agar test bisa menyuntikkan database palsu/in-memory tanpa
  /// menyentuh SQLite sungguhan (pola yang sama dipakai di Minggu 12).
  final Future<Database> Function() _openDb;

  /// Daftar catatan, diurutkan `updated_at DESC` (terbaru di atas).
  Future<List<Note>> fetchNotes() async {
    final db = await _openDb();
    final rows = await db.query('notes', orderBy: 'updated_at DESC');
    return rows.map(Note.fromMap).toList();
  }

  Future<Note?> getNote(int id) async {
    final db = await _openDb();
    final rows = await db.query('notes', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Note.fromMap(rows.first);
  }

  /// Catatan baru selalu `dirty = true` sampai `markAllSynced()` dipanggil
  /// setelah "server" menjawab sukses.
  Future<Note> addNote({required String title, String body = ''}) async {
    final db = await _openDb();
    final note = Note(
      title: title,
      body: body,
      updatedAt: DateTime.now(),
      dirty: true,
    );
    final id = await db.insert('notes', note.toMap());
    // `copyWith` sengaja tidak mengubah id, jadi kita buat ulang objeknya
    // dengan id hasil insert.
    return note._withId(id);
  }

  /// Edit selalu memperbarui `updated_at` **dan** menandai `dirty = true`,
  /// sesuai aturan konflik *last-write-wins*.
  Future<Note> updateNote(
    int id, {
    required String title,
    required String body,
  }) async {
    final db = await _openDb();
    final note = Note(
      id: id,
      title: title,
      body: body,
      updatedAt: DateTime.now(),
      dirty: true,
    );
    await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
    return note;
  }

  Future<void> deleteNote(int id) async {
    final db = await _openDb();
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  /// Kosongkan seluruh catatan (dipakai menu "Kosongkan data demo" agar
  /// state *empty* bisa direproduksi).
  Future<void> deleteAllNotes() async {
    final db = await _openDb();
    await db.delete('notes');
  }

  /// Jumlah kandidat antrean sinkronisasi.
  Future<int> countDirty() async {
    final db = await _openDb();
    final rows =
        await db.rawQuery('SELECT COUNT(*) AS c FROM notes WHERE dirty = 1');
    return ((rows.first['c'] as num?)?.toInt() ?? 0);
  }

  /// Dipanggil **hanya setelah** "server" menjawab sukses (2xx).
  Future<void> markAllSynced() async {
    final db = await _openDb();
    await db.update('notes', {'dirty': 0}, where: 'dirty = 1');
  }
}

extension on Note {
  Note _withId(int id) => Note(
        id: id,
        title: title,
        body: body,
        updatedAt: updatedAt,
        dirty: dirty,
      );
}
