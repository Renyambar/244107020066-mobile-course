import '../../../../core/failures.dart';
import '../entities/announcement.dart';
import '../repositories/announcement_repository.dart';

/// Satu operasi bisnis: **ambil satu pengumuman** dengan validasi [id].
///
/// Ia punya aturan bisnis nyata (id wajib berupa angka tidak kosong) sehingga
/// use case ini dibenarkan — berbeda dengan pengambilan daftar yang tidak
/// punya aturan tambahan dan boleh langsung repository -> state (lihat modul
/// bagian "Kapan use case perlu?").
class GetAnnouncement {
  const GetAnnouncement(this._repository);

  final AnnouncementRepository _repository;

  Future<Result<Announcement>> call(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      return failure(const ValidationFailure('Id pengumuman wajib diisi'));
    }
    if (int.tryParse(trimmed) == null) {
      return failure(const ValidationFailure('Id pengumuman tidak valid'));
    }
    return _repository.getById(trimmed);
  }
}
