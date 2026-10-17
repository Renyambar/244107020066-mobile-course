import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../../domain/usecases/get_announcement.dart';
import '../../data/repositories/announcement_repository_impl.dart';
import '../../data/sources/demo_announcement_source.dart';

// --- Data layer: implementasi disuntikkan sekali ---

final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepositoryImpl(DemoAnnouncementSource());
});

// --- Domain layer: use case menerima abstraksi ---

final getAnnouncementProvider = Provider<GetAnnouncement>((ref) {
  return GetAnnouncement(ref.watch(announcementRepositoryProvider));
});

// --- Presentation layer: state ---

/// Daftar pengumuman — pengambilan daftar tidak punya aturan bisnis tambahan,
/// jadi dipanggil langsung repository -> state (tanpa use case wrapper).
final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  final result = await ref.watch(announcementRepositoryProvider).getAll();
  if (result.failure != null) throw result.failure!;
  return result.value ?? const <Announcement>[];
});

/// Detail satu pengumuman (lewat use case karena ada validasi id).
final announcementDetailProvider =
    FutureProvider.family<Announcement, String>((ref, id) async {
  final result = await ref.watch(getAnnouncementProvider)(id);
  if (result.failure != null) throw result.failure!;
  return result.value!;
});
