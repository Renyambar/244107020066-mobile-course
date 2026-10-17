import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/announcements/domain/entities/announcement.dart';
import 'package:campus_notify/features/announcements/domain/repositories/announcement_repository.dart';
import 'package:campus_notify/features/announcements/domain/usecases/get_announcement.dart';

// --- Repository palsu (tanpa SQLite maupun jaringan) ------------------------

class FakeAnnouncementRepository implements AnnouncementRepository {
  FakeAnnouncementRepository({this.items = const [], this.fail = false});

  final List<Announcement> items;
  final bool fail;

  @override
  Future<Result<List<Announcement>>> getAll() async =>
      fail ? failure(const LocalFailure('gagal membaca')) : success(items);

  @override
  Future<Result<Announcement>> getById(String id) async {
    if (fail) return failure(const LocalFailure('db locked (simulasi)'));
    for (final a in items) {
      if (a.id == id) return success(a);
    }
    return failure(LocalFailure('Pengumuman #$id tidak ditemukan'));
  }
}

void main() {
  test('GetAnnouncement meneruskan pengumuman yang ditemukan', () async {
    final repo = FakeAnnouncementRepository(items: [
      const Announcement(id: '1', title: 'Kuliah Pengganti', body: 'Ruangan A2'),
    ]);

    final result = await GetAnnouncement(repo)('1');

    expect(result.failure, isNull);
    expect(result.value!.title, 'Kuliah Pengganti');
  });

  test('GetAnnouncement menolak id non-angka dengan ValidationFailure',
      () async {
    final repo = FakeAnnouncementRepository(items: const []);

    final result = await GetAnnouncement(repo)('bukan-angka');

    expect(result.failure, isA<ValidationFailure>());
    expect(result.value, isNull);
  });

  test('GetAnnouncement meneruskan failure repository tanpa melempar',
      () async {
    final repo = FakeAnnouncementRepository(fail: true);

    final result = await GetAnnouncement(repo)('1');

    expect(result.failure, isA<LocalFailure>());
    expect(result.value, isNull);
  });
}
