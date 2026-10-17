import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/data/repositories/note_repository.dart';
import 'package:week5_offline_notes/data/sync.dart';

/// Fake repository kedua: khusus menguji mekanisme **antrean sinkronisasi**
/// (dirty flag → markAllSynced) tanpa SQLite sungguhan.
class SyncFakeRepository extends NoteRepository {
  SyncFakeRepository(List<Note> items)
      : items = List<Note>.of(items),
        super(openDb: () => throw UnimplementedError());

  final List<Note> items;
  int markAllSyncedCalls = 0;

  @override
  Future<List<Note>> fetchNotes() async => items;

  @override
  Future<int> countDirty() async => items.where((n) => n.dirty).length;

  @override
  Future<void> markAllSynced() async {
    markAllSyncedCalls++;
    for (var i = 0; i < items.length; i++) {
      items[i] = items[i].copyWith(dirty: false);
    }
  }
}

void main() {
  final now = DateTime(2026, 9, 18, 10, 30);

  Map<String, Object?> cacheRow({
    int id = 1,
    String payload = '{"id":1,"title":"Judul post","body":"Isi post"}',
  }) =>
      {'id': id, 'payload': payload, 'cached_at': now.toIso8601String()};

  // --- Antrean sinkronisasi ------------------------------------------------

  test('syncNotes menandai semua catatan kotor sebagai sinkron', () async {
    final repo = SyncFakeRepository([
      Note(title: 'a', updatedAt: now, dirty: true),
      Note(title: 'b', updatedAt: now, dirty: true),
      Note(title: 'c', updatedAt: now, dirty: false),
    ]);

    final uploaded = await syncNotes(repo, delay: Duration.zero);

    expect(uploaded, 2);
    expect(repo.markAllSyncedCalls, 1);
    expect(await repo.countDirty(), 0, reason: 'badge harus kembali 0');
  });

  test('syncNotes saat offline menahan antrean (dirty tetap ada)', () async {
    final repo = SyncFakeRepository([
      Note(title: 'a', updatedAt: now, dirty: true),
    ]);

    final uploaded = await syncNotes(repo, offline: true);

    expect(uploaded, 0, reason: 'tidak ada yang diunggah saat offline');
    expect(repo.markAllSyncedCalls, 0, reason: 'markAllSynced tidak dipanggil');
    expect(await repo.countDirty(), 1, reason: 'antrean menunggu online');

    final report = SyncReport(uploaded: uploaded, offline: true);
    expect(report.queued, isTrue);
    expect(report.message, contains('offline'));
  });

  test('syncNotes dengan antrean kosong tidak menyentuh database', () async {
    final repo = SyncFakeRepository([
      Note(title: 'a', updatedAt: now, dirty: false),
    ]);

    final uploaded = await syncNotes(repo, delay: Duration.zero);

    expect(uploaded, 0);
    expect(repo.markAllSyncedCalls, 0);
  });

  // --- Cache-first read ----------------------------------------------------

  test('cache-first offline: baca cache tanpa memanggil jaringan', () async {
    final source = InMemoryPostCacheSource([cacheRow()]);
    var fetchCalls = 0;

    final posts = await loadPostsCacheFirst(
      source,
      fetchRemote: () async {
        fetchCalls++;
        return [
          {'id': 9, 'title': 'baru', 'body': 'dari server'}
        ];
      },
      forceOffline: true,
    );

    expect(posts, hasLength(1));
    expect(posts.first.title, 'Judul post', reason: 'dari cache lokal');
    expect(fetchCalls, 0, reason: 'jaringan tidak boleh disentuh saat offline');
  });

  test('cache-first: kunjungan pertama menunggu jaringan (state loading)', () async {
    final source = InMemoryPostCacheSource();

    final posts = await loadPostsCacheFirst(
      source,
      fetchRemote: () async => [
        {'id': 4, 'title': 'post pertama', 'body': 'isi'}
      ],
      forceOffline: false,
    );

    expect(posts.single.title, 'post pertama');
    expect(await source.readRows(), hasLength(1),
        reason: 'hasil download disimpan ke cache');
  });

  test('cache basi memicu refresh di background, UI tetap dapat cache', () async {
    final oldStamp = DateTime(2026, 9, 18, 9).toIso8601String();
    final source = InMemoryPostCacheSource([
      {'id': 1, 'payload': '{"title":"lama","body":""}', 'cached_at': oldStamp},
    ]);
    Future<List<CachedPost>>? background;

    final posts = await loadPostsCacheFirst(
      source,
      fetchRemote: () async => [
        {'id': 1, 'title': 'baru', 'body': 'hasil refresh'}
      ],
      forceOffline: false,
      now: now,
      onBackgroundRefresh: (task) => background = task,
    );

    expect(posts.single.title, 'lama', reason: 'UI langsung dari cache');
    expect(background, isNotNull, reason: 'refresh dijadwalkan di background');

    final refreshed = await background;
    expect(refreshed!.single.title, 'baru');
    final rows = await source.readRows();
    expect(rows, hasLength(1), reason: 'isi cache sudah diganti');
    expect(isCacheFresh(refreshed, now: now), isTrue);
  });

  // --- Model cache tahan-gagal ---------------------------------------------

  test('CachedPost dari payload rusak tetap aman', () {
    final post = CachedPost.fromRow({
      'id': 5,
      'payload': 'bukan-json{{',
      'cached_at': 'bukan-tanggal',
    });

    expect(post.id, 5);
    expect(post.title, '');
    expect(post.body, '');
    expect(post.cachedAt, DateTime.fromMillisecondsSinceEpoch(0));
  });
}
