/// Fungsi murni formatting & parsing (Refactoring Challenge #2 modul).
///
/// Berisi **tanpa satu pun import Flutter/package** sehingga bisa diuji unit
/// test langsung tanpa widget maupun Firebase. Menempatkan logika ini di sini
/// membuat presentation steril dari `DateFormat`/`jsonDecode`/parsing rute.
library;

import '../routes.dart';

// --- Formatting tanggal ----------------------------------------------------

const List<String> _bulan = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

/// Format ringkas `27 Sep 2026` — dipakai UI agar tidak ada `DateFormat`
/// di dalam widget.
String formatDate(DateTime date) =>
    '${date.day} ${_bulan[date.month - 1]} ${date.year}';

/// Format lengkap `27 Sep 2026 • 13.45` (menit dua digit).
String formatDateTime(DateTime date) {
  final hh = date.hour.toString().padLeft(2, '0');
  final mm = date.minute.toString().padLeft(2, '0');
  return '${formatDate(date)} • $hh.$mm';
}

// --- Parsing payload rute ---------------------------------------------------

/// Parsing murni `data` payload push -> rute tujuan yang diizinkan.
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
/// Pesan **hanya-data** tidak boleh menampilkan banner otomatis — sesuai tabel
/// "Notification payload vs data payload" pada modul.
bool hasNotificationPayload({String? title, String? body}) =>
    title != null || body != null;

/// Ambil `id` pengumuman dari payload data, atau null bila tidak ada/invalid.
String? announcementIdFromMessage(Map<String, dynamic> data) {
  final raw = data['id'];
  final id = raw is String ? raw : raw?.toString();
  if (id == null || id.trim().isEmpty) return null;
  return int.tryParse(id.trim()) == null ? null : id.trim();
}

/// Potongan token yang aman ditampilkan: 12 karakter pertama + elipsis.
///
/// Token penuh tidak pernah masuk UI/screenshot (permintaan modul).
String shortToken(String token) {
  if (token.length <= 12) return token;
  return '${token.substring(0, 12)}…';
}
