import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Tempat tunggal keluar-masuknya token sesi (modul langkah 1).
///
/// Prinsip keamanan yang dipatuhi kelas ini:
/// - Access & refresh token **hanya** disimpan di `flutter_secure_storage`
///   (Android Keystore / iOS Keychain / WebCrypto), tidak pernah di
///   `SharedPreferences` yang tidak terenkripsi.
/// - Token tidak pernah dicetak penuh ke log maupun ke UI.
class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  Future<void> save({required String access, required String refresh}) async {
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  /// Perbarui access token saja; refresh token dipertahankan.
  Future<void> saveAccess(String access) =>
      _storage.write(key: _accessKey, value: access);

  Future<String?> readAccess() => _storage.read(key: _accessKey);
  Future<String?> readRefresh() => _storage.read(key: _refreshKey);

  /// Hapus seluruh sesi — dipanggil saat logout atau refresh token mati.
  Future<void> clear() => _storage.deleteAll();
}
