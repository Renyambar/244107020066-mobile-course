/// Kontrak penyimpanan sesi (token) — kebutuhan domain.
///
/// Interface ini hidup di `domain` karena use case & state aplikasi *membutuhkan*
/// kemampuan menyimpan/membaca sesi, tetapi domain **tidak tahu** cara
/// menatakannya (secure storage, SQLite, in-memory, ...). Implementasi asli
/// (`SecureSessionStore`) berada di `data`, disuntikkan lewat provider.
///
/// Inilah Dependency Inversion: domain mendefinisikan kontrak, data
/// mengimplementasikannya.
abstract class SessionStore {
  /// Simpan sepasang token sesi (menimpa yang lama).
  Future<void> save({required String access, required String refresh});

  /// Perbarui access token saja; refresh token dipertahankan.
  Future<void> saveAccess(String access);

  Future<String?> readAccess();
  Future<String?> readRefresh();

  /// Hapus seluruh sesi — dipanggil saat logout atau refresh token mati.
  Future<void> clear();
}
