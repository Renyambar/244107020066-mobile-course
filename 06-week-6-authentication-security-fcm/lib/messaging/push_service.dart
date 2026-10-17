import 'dart:async';

/// Kontrak layanan push yang dipakai seluruh UI (modul bagian FCM).
///
/// Dua implementasi:
/// - [FcmPushService] (`fcm_push_service.dart`) — Firebase Cloud Messaging asli.
/// - [DemoPushService] (`demo_push_service.dart`) — simulasi, dipakai saat
///   Firebase belum terkonfigurasi (mis. belum ada `firebase_options.dart`)
///   sehingga alur token lifecycle & tiga app state tetap bisa didemonstrasikan.
///
/// Keduanya mengeluarkan event lewat bentuk data yang sama ([PushMessage]),
/// jadi lapisan UI tidak perlu tahu sedang memakai backend yang mana.
enum PushBackend { fcm, demo }

/// Model pesan push netral — dipetakan dari `RemoteMessage` (FCM) atau dari
/// simulator internal.
class PushMessage {
  const PushMessage({this.title, this.body, this.data = const {}});

  final String? title;
  final String? body;
  final Map<String, dynamic> data;

  static PushMessage fromMap(Map<String, dynamic> map) => PushMessage(
        title: map['title'] as String?,
        body: map['body'] as String?,
        data: (map['data'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
}

/// Status izin notifikasi.
enum PushPermission { unknown, granted, denied, provisional }

/// Hasil langkah init layanan push.
class PushInitResult {
  const PushInitResult({
    required this.backend,
    required this.permission,
    this.token,
    this.topic,
  });

  final PushBackend backend;
  final PushPermission permission;

  /// Token yang sudah dipotong — aman untuk ditampilkan.
  final String? token;
  final String? topic;

  bool get isRealFcm => backend == PushBackend.fcm;
}

abstract class PushService {
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
  Future<String?> getToken({required Future<void> Function(String token) onRegister});
  Future<void> subscribeToTopic(String topic);
  Future<void> unsubscribeFromTopic(String topic);

  /// Tampilkan banner untuk pesan foreground.
  ///
  /// Pada FCM Android memakai `flutter_local_notifications` (sistem);
  /// pada Web/Demo memakai banner in-app (karena plugin lokal tidak didukung).
  Future<void> showForegroundBanner(PushMessage message);

  Future<void> dispose();
}
