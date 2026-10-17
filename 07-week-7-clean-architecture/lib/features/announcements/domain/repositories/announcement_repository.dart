import '../../../../core/failures.dart';
import '../entities/announcement.dart';

/// Kontrak pengumuman yang dibutuhkan domain (interface di `domain`).
///
/// Implementasi (`AnnouncementRepositoryImpl`) memakai sumber data contoh
/// di `data` dan tidak pernah diketahui presentation.
abstract class AnnouncementRepository {
  Future<Result<List<Announcement>>> getAll();

  /// Ambil satu pengumuman berdasarkan [id] — null/gagal memakai [Failure].
  Future<Result<Announcement>> getById(String id);
}
