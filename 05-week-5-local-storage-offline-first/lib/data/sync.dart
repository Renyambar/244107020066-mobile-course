import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'local/db.dart';
import 'repositories/note_repository.dart';

/// Refactoring #2 (lib/data/sync.dart) — codelab Minggu 5.
///
/// File ini memisahkan **logika sinkronisasi & cache** dari repository,
/// supaya `NoteRepository` tetap fokus pada CRUD lokal.
///
/// Tiga mekanisme offline-first ada di sini:
/// 1. **Cache-first read** — [loadPostsCacheFirst] membaca `cached_posts`
///    lebih dulu lalu me-refresh jaringan di background.
/// 2. **Dirty flag** — penanda `dirty = 1` dikelola repository.
/// 3. **Antrean sinkronisasi** — [syncNotes] memproses antrean berurutan
///    hanya saat online.

/// Aturan konflik yang dipilih dan didokumentasikan:
/// **last-write-wins berdasarkan `updated_at`**. Tanpa aturan eksplisit,
/// sinkronisasi dua arah akan menimpa data secara diam-diam.
const String conflictRule = 'Last-Write-Wins (updated_at terbaru menang)';

// ---------------------------------------------------------------------------
// Model + sumber cache post (tabel `cached_posts`)
// ---------------------------------------------------------------------------

/// Satu baris hasil `GET /posts` yang sudah disimpan ke cache lokal.
class CachedPost {
  const CachedPost({
    required this.id,
    required this.title,
    required this.body,
    required this.cachedAt,
  });

  final int id;
  final String title;
  final String body;

  /// Kapan baris ini terakhir ditulis ke cache.
  final DateTime cachedAt;

  /// Parsing tahan-gagal: JSON rusak/hilang tidak membuat crash UI.
  factory CachedPost.fromRow(Map<String, Object?> row) {
    final id = (row['id'] as num?)?.toInt() ?? 0;
    var title = '';
    var body = '';
    try {
      final payload = jsonDecode(row['payload'] as String? ?? '{}');
      if (payload is Map<String, dynamic>) {
        title = payload['title'] as String? ?? '';
        body = payload['body'] as String? ?? '';
      }
    } catch (_) {
      // payload rusak: pakai nilai kosong, baris lain tetap tampil.
    }
    return CachedPost(
      id: id,
      title: title,
      body: body,
      cachedAt: DateTime.tryParse(row['cached_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

/// Abstraksi atas tabel `cached_posts` supaya logika cache-first bisa diuji
/// dengan sumber in-memory (tanpa SQLite sungguhan).
abstract class PostCacheSource {
  Future<List<Map<String, Object?>>> readRows();

  /// Ganti seluruh isi cache dengan hasil fetch terbaru.
  Future<void> replaceAll(List<Map<String, Object?>> rows);
}

class DbPostCacheSource implements PostCacheSource {
  DbPostCacheSource({Future<Database> Function()? openDb})
      : _openDb = openDb ?? openNotesDb;

  final Future<Database> Function() _openDb;

  @override
  Future<List<Map<String, Object?>>> readRows() async {
    final db = await _openDb();
    return db.query('cached_posts', orderBy: 'id ASC');
  }

  @override
  Future<void> replaceAll(List<Map<String, Object?>> rows) async {
    final db = await _openDb();
    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      await txn.delete('cached_posts');
      final batch = txn.batch();
      for (final row in rows) {
        batch.insert('cached_posts', {
          'id': (row['id'] as num?)?.toInt(),
          'payload': jsonEncode(row),
          'cached_at': now,
        });
      }
      await batch.commit(noResult: true);
    });
  }
}

/// Sumber cache in-memory untuk test (tanpa database sungguhan).
class InMemoryPostCacheSource implements PostCacheSource {
  InMemoryPostCacheSource([List<Map<String, Object?>>? seed])
      : rows = [...?seed];

  final List<Map<String, Object?>> rows;

  @override
  Future<List<Map<String, Object?>>> readRows() async =>
      List.unmodifiable(rows);

  @override
  Future<void> replaceAll(List<Map<String, Object?>> newRows) async {
    rows
      ..clear()
      ..addAll(newRows);
  }
}

// ---------------------------------------------------------------------------
// Cache-first read
// ---------------------------------------------------------------------------

/// Baca cache lebih dulu: **UI tidak pernah menunggu jaringan**.
///
/// * [forceOffline] `true` → jaringan dilewatkan sepenuhnya, cache tetap tampil.
/// * Kunjungan pertama (cache kosong, online) → [awaitRefresh] `true` agar
///   UI menampilkan state loading yang jujur, bukan empty-state palsu.
/// * Cache basi (lebih tua [maxAge]) → refresh dijalankan di background oleh
///   pemanggil ([onBackgroundRefresh]) sehingga invalidate tidak berputar.
Future<List<CachedPost>> loadPostsCacheFirst(
  PostCacheSource source, {
  required Future<List<Map<String, dynamic>>> Function() fetchRemote,
  required bool forceOffline,
  Duration maxAge = const Duration(minutes: 5),
  bool awaitFirstLoad = true,
  void Function(Future<List<CachedPost>> task)? onBackgroundRefresh,
  DateTime? now,
}) async {
  final cached = (await source.readRows()).map(CachedPost.fromRow).toList();

  if (forceOffline) {
    debugPrint('[cache] offline → ${cached.length} post dari cache lokal');
    return cached;
  }

  if (cached.isEmpty && awaitFirstLoad) {
    debugPrint('[cache] cache kosong → ambil dari jaringan (state loading)');
    return downloadPosts(source, fetchRemote);
  }

  final fresh = isCacheFresh(cached, maxAge: maxAge, now: now);
  debugPrint(
    '[cache] ${cached.length} post dari cache lokal '
    '(hangat: $fresh)',
  );
  if (!fresh && onBackgroundRefresh != null) {
    onBackgroundRefresh(downloadPosts(source, fetchRemote));
  }
  return cached;
}

/// `true` bila cache terbaru masih lebih muda dari [maxAge].
bool isCacheFresh(
  List<CachedPost> posts, {
  Duration maxAge = const Duration(minutes: 5),
  DateTime? now,
}) {
  if (posts.isEmpty) return false;
  final newest = posts.map((p) => p.cachedAt).reduce((a, b) => a.isAfter(b) ? a : b);
  final clock = now ?? DateTime.now();
  return clock.difference(newest) <= maxAge;
}

/// Ambil `GET /posts` (JSONPlaceholder, endpoint yang sama dengan Minggu 4),
/// lalu ganti isi cache. Exception dibiarkan naik agar pemanggil memutuskan
/// apakah mempertahankan cache lama.
Future<List<CachedPost>> downloadPosts(
  PostCacheSource source,
  Future<List<Map<String, dynamic>>> Function() fetchRemote,
) async {
  final rows = await fetchRemote();
  await source.replaceAll(rows);
  debugPrint('[cache] refresh jaringan OK → ${rows.length} post disimpan');
  return rows.map((row) => CachedPost.fromRow({
        'id': row['id'],
        'payload': jsonEncode(row),
        'cached_at': DateTime.now().toIso8601String(),
      })).toList();
}

/// `GET /posts` memakai Dio (konfigurasi sama dengan Minggu 4).
Future<List<Map<String, dynamic>>> fetchRemotePosts(Dio dio) async {
  final response = await dio.get<List<dynamic>>('/posts');
  return (response.data ?? const <dynamic>[])
      .whereType<Map<String, dynamic>>()
      .toList();
}

// ---------------------------------------------------------------------------
// Sinkronisasi antrean catatan kotor (dirty)
// ---------------------------------------------------------------------------

/// Simulasi upload antrean `dirty`.
///
/// Pada project nyata, kirim tiap catatan ke REST API di sini dan panggil
/// `markAllSynced()` **hanya** setelah server menjawab 2xx. Codelab ini belum
/// punya backend tulis, jadi server disimulasikan dengan delay.
///
/// Returns jumlah catatan yang berhasil ditandai tersinkron.
Future<int> syncNotes(
  NoteRepository repo, {
  bool offline = false,
  Duration delay = const Duration(seconds: 1),
}) async {
  final dirtyCount = await repo.countDirty();
  if (offline) {
    debugPrint('[sync] mode offline → $dirtyCount catatan tetap antre');
    return 0;
  }
  if (dirtyCount == 0) {
    debugPrint('[sync] antrean kosong, tidak ada yang diunggah');
    return 0;
  }
  debugPrint('[sync] unggah $dirtyCount catatan (simulasi server) ...');
  await Future.delayed(delay);
  await repo.markAllSynced();
  debugPrint('[sync] selesai → dirty = 0 (last-write-wins: $conflictRule)');
  return dirtyCount;
}

/// Hasil sekali jalan `syncNotes`, dibaca oleh UI untuk pesan snackbar.
class SyncReport {
  const SyncReport({required this.uploaded, required this.offline});

  /// Jumlah catatan yang ditandai tersinkron (0 bila offline/antrean kosong).
  final int uploaded;

  /// `true` bila sinkronisasi ditahan karena mode offline.
  final bool offline;

  bool get queued => offline || uploaded == 0;

  String get message {
    if (offline) return 'Mode offline — sinkronisasi ditunda';
    if (uploaded == 0) return 'Tidak ada perubahan untuk disinkronkan';
    return '$uploaded catatan tersinkron';
  }
}
