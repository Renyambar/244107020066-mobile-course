import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local/note.dart';
import 'prefs.dart';
import 'repositories/note_repository.dart';
import 'sync.dart';

/// Seluruh provider aplikasi dipusatkan di sini (modul menempatkan
/// `prefsRepositoryProvider`/`darkModeProvider` di `settings_page.dart`;
/// karena tema juga dibutuhkan `MaterialApp` di `main.dart`, saya pindahkan
/// ke satu file agar tidak ada import melingkar antar-halaman).
///
/// UI hanya `watch` provider — tidak pernah menyentuh SQLite/SharedPreferences.

// ---------------------------------------------------------------------------
// Preferensi (key-value)
// ---------------------------------------------------------------------------

final prefsRepositoryProvider =
    Provider<PrefsRepository>((ref) => PrefsRepository());

/// Langkah 2 — toggle tema gelap/terang.
class DarkModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.watch(prefsRepositoryProvider).getDarkMode();

  Future<void> toggle() async {
    final next = !(state.value ?? false);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(prefsRepositoryProvider).setDarkMode(next);
      return next;
    });
  }
}

final darkModeProvider =
    AsyncNotifierProvider<DarkModeNotifier, bool>(
      DarkModeNotifier.new,
      // Retry otomatis dimatikan: error jadi final dan mudah diuji.
      retry: (retryCount, error) => null,
    );

/// Waktu terakhir aplikasi dibuka (ditulis saat aplikasi start).
class LastOpenedNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() =>
      ref.watch(prefsRepositoryProvider).getLastOpened();

  Future<void> markNow() async {
    await ref.read(prefsRepositoryProvider).markOpenedNow();
    ref.invalidateSelf(asReload: true);
  }
}

final lastOpenedProvider =
    AsyncNotifierProvider<LastOpenedNotifier, String?>(
      LastOpenedNotifier.new,
      retry: (retryCount, error) => null,
    );

// ---------------------------------------------------------------------------
// Jaringan (untuk cache-first read)
// ---------------------------------------------------------------------------

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://jsonplaceholder.typicode.com',
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      headers: {'Accept': 'application/json'},
    ),
  );
  return dio;
});

// ---------------------------------------------------------------------------
// Catatan (SQLite lewat repository)
// ---------------------------------------------------------------------------

final noteRepositoryProvider =
    Provider<NoteRepository>((ref) => NoteRepository());

class NotesNotifier extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() async {
    // Exception repository otomatis menjadi AsyncError.
    final notes = await ref.watch(noteRepositoryProvider).fetchNotes();
    debugPrint('[notes] ${notes.length} catatan dibaca dari SQLite');
    return notes;
  }

  /// Semua mutasi memanggil repository lalu **me-invalidate provider di
  /// sini** (bukan di widget acak), sehingga badge dirty ikut akurat.
  Future<void> addNote({required String title, String body = ''}) async {
    final repo = ref.read(noteRepositoryProvider);
    final note = await repo.addNote(title: title, body: body);
    debugPrint('[notes] tambah #${note.id} "$title" → dirty = 1');
    ref.invalidateSelf(asReload: true);
  }

  Future<void> updateNote(
    int id, {
    required String title,
    required String body,
  }) async {
    final repo = ref.read(noteRepositoryProvider);
    await repo.updateNote(id, title: title, body: body);
    debugPrint('[notes] edit #$id → updated_at & dirty = 1 ($conflictRule)');
    ref.invalidateSelf(asReload: true);
  }

  Future<void> deleteNote(int id) async {
    final repo = ref.read(noteRepositoryProvider);
    await repo.deleteNote(id);
    debugPrint('[notes] hapus #$id');
    ref.invalidateSelf(asReload: true);
  }

  /// Menjalankan antrean sinkronisasi, lalu me-refresh daftar sehingga
  /// badge "belum tersinkron" ikut berubah.
  Future<SyncReport> syncNow({required bool offline}) async {
    final repo = ref.read(noteRepositoryProvider);
    final uploaded = await syncNotes(repo, offline: offline);
    ref.invalidateSelf(asReload: true);
    return SyncReport(uploaded: uploaded, offline: offline);
  }
}

final notesProvider =
    AsyncNotifierProvider<NotesNotifier, List<Note>>(
      NotesNotifier.new,
      retry: (retryCount, error) => null,
    );

/// Badge antrean sinkronisasi — diturunkan dari daftar agar selalu konsisten
/// dengan isi tabel `notes` (repository.countDirty dipakai oleh `syncNotes`).
final dirtyCountProvider = Provider<int>((ref) {
  final notes = ref.watch(notesProvider).value ?? const <Note>[];
  return notes.where((n) => n.dirty).length;
});

// ---------------------------------------------------------------------------
// Simulasi offline deterministik
// ---------------------------------------------------------------------------

class ForceOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() {
    state = !state;
    debugPrint('[offline] forceOffline = $state');
  }
}

/// Toggle "paksa offline" agar demo/testing tidak bergantung pada kondisi
/// Wi-Fi kelas (codelab: simulasi offline yang deterministik).
final forceOfflineProvider =
    NotifierProvider<ForceOfflineNotifier, bool>(ForceOfflineNotifier.new);

// ---------------------------------------------------------------------------
// Cache-first post (Refactoring #2 — logika ada di data/sync.dart)
// ---------------------------------------------------------------------------

final postCacheSourceProvider =
    Provider<PostCacheSource>((ref) => DbPostCacheSource());

class PostsCacheNotifier extends AsyncNotifier<List<CachedPost>> {
  bool _running = false;

  @override
  Future<List<CachedPost>> build() {
    // Rebuild saat toggle offline: cache dibaca ulang tanpa sentuh jaringan.
    ref.watch(forceOfflineProvider);
    ref.watch(postCacheSourceProvider);
    return _load();
  }

  Future<List<CachedPost>> _load() async {
    final source = ref.read(postCacheSourceProvider);
    final offline = ref.read(forceOfflineProvider);
    return loadPostsCacheFirst(
      source,
      fetchRemote: () => fetchRemotePosts(ref.read(dioProvider)),
      forceOffline: offline,
      onBackgroundRefresh: (task) => unawaited(_settle(task)),
    );
  }

  /// Hasil refresh background masuk tanpa memutar-mutar `invalidate`
  /// (kalau di-invalidate, refresh akan terpicu lagi → loop tak berujung).
  Future<void> _settle(Future<List<CachedPost>> task) async {
    if (_running) return;
    _running = true;
    try {
      final fresh = await task;
      state = AsyncData(fresh);
    } catch (e) {
      debugPrint('[cache] refresh background gagal ($e) → cache lama dipakai');
    } finally {
      _running = false;
    }
  }

  /// Refresh manual (tarik-turun / tombol muat ulang).
  Future<void> reload() async {
    final offline = ref.read(forceOfflineProvider);
    final source = ref.read(postCacheSourceProvider);
    state = const AsyncLoading();
    try {
      if (offline) {
        state = AsyncData(await _load());
      } else {
        debugPrint('[cache] refresh manual → tunggu jaringan');
        state = AsyncData(
          await downloadPosts(
            source,
            () => fetchRemotePosts(ref.read(dioProvider)),
          ),
        );
      }
    } catch (e, st) {
      // Jaringan mati: kembalikan cache lama, jangan halaman error.
      debugPrint('[cache] refresh manual gagal ($e) → pakai cache');
      final cached = (await source.readRows()).map(CachedPost.fromRow).toList();
      state = cached.isEmpty ? AsyncError(e, st) : AsyncData(cached);
    }
  }
}

final postsCacheProvider =
    AsyncNotifierProvider<PostsCacheNotifier, List<CachedPost>>(
      PostsCacheNotifier.new,
      retry: (retryCount, error) => null,
    );

/// Catatan detail `/note/:id` — dibaca dari repository lokal (bukan state
/// halaman list), sesuai Refactoring #3.
final noteDetailProvider =
    FutureProvider.autoDispose.family<Note?, int>((ref, id) {
      return ref.watch(noteRepositoryProvider).getNote(id);
    });

// ---------------------------------------------------------------------------
// Helper khusus testing (tanpa database sungguhan & tanpa HTTP)
// ---------------------------------------------------------------------------

Future<List<Note>> readNotesOnce(ProviderContainer container) {
  final completer = Completer<List<Note>>();
  final sub = container.listen<AsyncValue<List<Note>>>(
    notesProvider,
    (previous, next) {
      if (next.isLoading || completer.isCompleted) return;
      next.whenData(completer.complete);
      if (next.hasError) {
        completer.completeError(
          next.error ?? StateError('unknown error'),
          next.stackTrace ?? StackTrace.empty,
        );
      }
    },
    fireImmediately: true,
  );
  return completer.future.whenComplete(sub.close);
}

Future<Object?> readNotesErrorOnce(ProviderContainer container) {
  final completer = Completer<Object?>();
  final sub = container.listen<AsyncValue<List<Note>>>(
    notesProvider,
    (previous, next) {
      if (next.isLoading || completer.isCompleted) return;
      completer.complete(next.error);
    },
    fireImmediately: true,
  );
  return completer.future.whenComplete(sub.close);
}
