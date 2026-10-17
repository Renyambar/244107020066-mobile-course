import '../entities/push_message.dart';

/// Kontrak layanan push yang dibutuhkan domain/presentation.
///
/// Interface ini adalah **satu-satunya** gambaran push yang diketahui lapisan
/// atas. Dua implementasi di `data`:
/// - [DemoPushGateway] — simulator, aktif secara default (lihat `bootstrap`).
/// - `FcmPushGateway` — adapter Firebase Cloud Messaging (template terpisah di
///   `docs/fcm_integration.md`, disuntikkan saat Firebase dikonfigurasi).
///
/// Inilah penerapan Open/Closed: menukar backend cukup mengganti implementasi
/// yang disuntikkan, tanpa mengubah satu baris pun di presentation.
abstract class PushGateway {
  PushBackend get backend;

  /// Stream pesan yang diterima saat aplikasi terbuka (foreground).
  Stream<PushMessage> get onMessage;

  /// Stream klik pesan saat aplikasi di background.
  Stream<PushMessage> get onMessageOpenedApp;

  /// Rotasi token perangkat (reinstall / clear data / rotasi keamanan).
  Stream<String> get onTokenRefresh;

  /// Pesan yang membuka aplikasi dari kondisi terminated, atau null.
  Future<PushMessage?> getInitialMessage();

  Future<PushPermission> requestPermission();

  /// Ambil registration token saat ini (belum tentu terdaftar di backend —
  /// pendaftaran adalah tanggung jawab use case [RegisterDevice]).
  Future<String?> getToken();

  Future<void> subscribeToTopic(String topic);
  Future<void> unsubscribeFromTopic(String topic);

  Future<void> dispose();
}
