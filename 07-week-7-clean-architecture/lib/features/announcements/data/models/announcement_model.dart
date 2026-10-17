import '../../domain/entities/announcement.dart';

/// Representasi pengumuman sebagai JSON + pemetaan ke entity.
class AnnouncementModel extends Announcement {
  const AnnouncementModel({
    required super.id,
    required super.title,
    required super.body,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }

  Announcement toEntity() => Announcement(id: id, title: title, body: body);
}
