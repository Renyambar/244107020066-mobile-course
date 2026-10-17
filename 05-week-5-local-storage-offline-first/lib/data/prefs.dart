import 'package:shared_preferences/shared_preferences.dart';

/// Langkah 1 (Repository preferensi) — codelab Minggu 5.
///
/// Seluruh akses key-value terpusat di sini, bukan tersebar di widget.
/// SharedPreferences hanya untuk **nilai primitif kecil** (tema, waktu
/// terakhir dibuka) — daftar catatan tidak pernah masuk ke sini.
class PrefsRepository {
  static const _darkModeKey = 'dark_mode';
  static const _lastOpenedKey = 'last_opened_at';

  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }

  Future<void> markOpenedNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastOpenedKey, DateTime.now().toIso8601String());
  }

  Future<String?> getLastOpened() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastOpenedKey);
  }

  /// Daftar kunci yang tersimpan — dipakai untuk dokumentasi/diagnostik.
  Future<List<String>> getKeys() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getKeys().toList()..sort();
  }
}
