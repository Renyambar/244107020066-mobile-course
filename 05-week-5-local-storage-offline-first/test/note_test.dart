import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/data/providers.dart';
import 'package:week5_offline_notes/data/repositories/note_repository.dart';

/// Repository palsu (fake) — menggantikan NoteRepository sungguhan.
/// `openDb` sengaja melempar error: test menjamin **tidak ada SQLite yang
/// dibuka** (pola injeksi yang sama dengan codelab Minggu 5).
class FakeNoteRepository extends NoteRepository {
  FakeNoteRepository({List<Note> items = const [], this.throwError = false})
      : items = List<Note>.of(items),
        super(openDb: () => throw UnimplementedError());

  final List<Note> items;
  final bool throwError;
  int markAllSyncedCalls = 0;

  @override
  Future<List<Note>> fetchNotes() async {
    if (throwError) throw Exception('db locked (simulasi)');
    return items;
  }

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
  // --- Unit test model -----------------------------------------------------

  test('fromMap aman terhadap field yang hilang', () {
    final note = Note.fromMap({'title': 'Belanja'});
    expect(note.title, 'Belanja');
    expect(note.body, '');
    expect(note.dirty, isFalse);
    expect(note.id, isNull);
    expect(note.updatedAt, DateTime.fromMillisecondsSinceEpoch(0));
  });

  test('flag dirty bertahan pada serialisasi', () {
    final note = Note(
      title: 'a',
      updatedAt: DateTime(2026, 9, 18),
      dirty: true,
    );
    final restored = Note.fromMap(note.toMap());
    expect(restored.dirty, isTrue);
    expect(restored.syncLabel, 'Belum tersinkron');
  });

  test('aturan konflik last-write-wins memilih updated_at terbaru', () {
    final older = Note(title: 'lama', updatedAt: DateTime(2026, 9, 18, 8));
    final newer = Note(title: 'baru', updatedAt: DateTime(2026, 9, 18, 9));
    expect(newer.winsOver(older), isTrue);
    expect(older.winsOver(newer), isFalse);
  });

  test('copyWith tidak mengubah id', () {
    final note = Note(
      id: 7,
      title: 'awal',
      updatedAt: DateTime(2026, 9, 18),
      dirty: true,
    );
    final edited = note.copyWith(title: 'ubah', dirty: false);
    expect(edited.id, 7);
    expect(edited.title, 'ubah');
    expect(edited.dirty, isFalse);
    expect(note.title, 'awal', reason: 'objek asli tidak boleh berubah');
  });

  // --- Provider dengan repository palsu -----------------------------------

  test('provider sukses dengan repository palsu', () async {
    final container = ProviderContainer(
      overrides: [
        noteRepositoryProvider.overrideWithValue(
          FakeNoteRepository(items: [
            Note(title: 'Tes', updatedAt: DateTime.now(), dirty: true),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    final notes = await readNotesOnce(container);
    expect(notes.length, 1);
    expect(notes.first.title, 'Tes');
    expect(container.read(dirtyCountProvider), 1);
  });

  test('provider error dengan repository palsu', () async {
    final container = ProviderContainer(
      overrides: [
        noteRepositoryProvider.overrideWithValue(
          FakeNoteRepository(throwError: true),
        ),
      ],
    );
    addTearDown(container.dispose);

    // Pola codelab: `provider.future` melempar error repository sebagai
    // Future yang gagal (Riverpod mengubahnya menjadi AsyncError).
    await expectLater(
      container.read(notesProvider.future),
      throwsA(isA<Exception>()),
    );
    expect(container.read(notesProvider).hasError, isTrue);
  });
}
