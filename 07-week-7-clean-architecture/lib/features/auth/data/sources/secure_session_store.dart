import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/repositories/session_store.dart';

/// Implementasi [SessionStore] memakai `flutter_secure_storage`
/// (Android Keystore / iOS Keychain / WebCrypto).
///
/// Prinsip keamanan yang dipatuhi:
/// - Access & refresh token **hanya** disimpan di secure storage terenkripsi,
///   tidak pernah di `SharedPreferences` yang tidak terenkripsi.
/// - Token tidak pernah dicetak penuh ke log maupun ke UI.
///
/// Satu-satunya tempat `FlutterSecureStorage` disentuh ada di file ini —
/// lapisan presentation tidak pernah mengimpornya (lihat hasil grep sterilitas).
class SecureSessionStore implements SessionStore {
  SecureSessionStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  @override
  Future<void> save({required String access, required String refresh}) async {
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  @override
  Future<void> saveAccess(String access) =>
      _storage.write(key: _accessKey, value: access);

  @override
  Future<String?> readAccess() => _storage.read(key: _accessKey);

  @override
  Future<String?> readRefresh() => _storage.read(key: _refreshKey);

  @override
  Future<void> clear() => _storage.deleteAll();
}
