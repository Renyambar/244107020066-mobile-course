import '../../../../core/failures.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../models/announcement_model.dart';
import '../sources/demo_announcement_source.dart';

/// Implementasi [AnnouncementRepository] di lapisan `data`.
class AnnouncementRepositoryImpl implements AnnouncementRepository {
  AnnouncementRepositoryImpl(this._source);

  final DemoAnnouncementSource _source;

  @override
  Future<Result<List<Announcement>>> getAll() async {
    try {
      final raw = await _source.fetchAll();
      final list = raw
          .map((m) => AnnouncementModel.fromJson(m).toEntity())
          .toList(growable: false);
      return success(list);
    } catch (e) {
      return failure(LocalFailure('Gagal membaca pengumuman: $e'));
    }
  }

  @override
  Future<Result<Announcement>> getById(String id) async {
    try {
      final raw = await _source.fetchAll();
      final index = raw.indexWhere((m) => '${m['id']}' == id);
      if (index == -1) {
        return failure(LocalFailure('Pengumuman #$id tidak ditemukan'));
      }
      return success(AnnouncementModel.fromJson(raw[index]).toEntity());
    } catch (e) {
      return failure(LocalFailure('Gagal membaca pengumuman: $e'));
    }
  }
}
