import '../routes.dart';

/// Parsing murni `data` payload FCM -> rute tujuan (Refactoring Challenge #2).
///
/// Dipisah dari Firebase sehingga bisa diuji unit-test tanpa SDK apa pun.
///
/// Aturan:
/// - `route` kosong / hilang -> `/` (halaman utama).
/// - Nilai tanpa diawali slash ditambahkan slash (`pengumuman/3` -> `/pengumuman/3`).
/// - Rute di luar *allow-list* [AppRoutes] ditolak dan diarahkan ke `/`
///   (mencegah payload nakal membuka halaman acak).
String routeFromMessage(Map<String, dynamic> data) {
  final raw = data['route'];
  if (raw is! String || raw.trim().isEmpty) return AppRoutes.home;
  var route = raw.trim();
  if (!route.startsWith('/')) route = '/$route';
  if (!AppRoutes.isAllowed(route)) return AppRoutes.home;
  return route;
}

/// True bila payload membawa bagian `notification` (title/body).
///
/// Menjadi penentu apakah sebuah pesan layak menampilkan banner ke manusia.
/// Pesan **hanya-data** tidak boleh menampilkan banner otomatis — hanya
/// diteruskan ke handler — sesuai tabel "Notification payload vs data payload"
/// pada modul. Pemisahan ini membuat keputusan tersebut bisa diuji unit test
/// tanpa Firebase.
bool hasNotificationPayload({String? title, String? body}) =>
    title != null || body != null;

/// Ambil `id` pengumuman dari payload data, atau null bila tidak ada/invalid.
String? announcementIdFromMessage(Map<String, dynamic> data) {
  final raw = data['id'];
  final id = raw is String ? raw : (raw?.toString());
  if (id == null || id.trim().isEmpty) return null;
  return int.tryParse(id.trim()) == null ? null : id.trim();
}
