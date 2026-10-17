/// Pengumuman kampus (domain murni Dart, tanpa mapping).
class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
  });

  final String id;
  final String title;
  final String body;
}
