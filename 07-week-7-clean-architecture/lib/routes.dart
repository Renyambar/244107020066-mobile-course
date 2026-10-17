/// Konstanta rute aplikasi (Refactoring Challenge #1).
///
/// Deep link dari notifikasi (`data.route`) dan GoRouter memakai konstanta yang
/// sama sehingga tidak ada string rute yang tercecer di berbagai file.
library;

/// Seluruh rute yang diizinkan aplikasi.
///
/// Menjadi *allow-list*: `routeFromMessage()` hanya mengembalikan rute yang
/// ada di set ini, sehingga payload `data.route` nakal dari luar tidak bisa
/// mengarahkan pengguna ke halaman acak.
abstract final class AppRoutes {
  static const String login = '/login';
  static const String home = '/';
  static const String announcementPrefix = '/pengumuman/';

  /// Rute tujuan topik broadcast kampus.
  static const String topicLanding = '/pengumuman/1';

  /// Bangun rute detail pengumuman dari [id].
  static String announcement(String id) => '$announcementPrefix$id';

  /// Daftar rute yang diizinkan untuk navigasi dari notifikasi.
  static const Set<String> allowedExact = {login, home};

  /// True bila [location] adalah rute detail pengumuman yang sah
  /// (`/pengumuman/<angka>`).
  static bool isAnnouncement(String location) {
    if (!location.startsWith(announcementPrefix)) return false;
    final id = location.substring(announcementPrefix.length);
    return id.isNotEmpty && int.tryParse(id) != null;
  }

  /// True bila [location] boleh dipakai sebagai tujuan deep link.
  static bool isAllowed(String location) =>
      allowedExact.contains(location) || isAnnouncement(location);
}
