import 'dart:async';
import 'dart:math';

import '../data/device_api.dart';
import 'push_service.dart';

/// Implementasi simulasi layanan push.
///
/// Dipakai saat Firebase belum terkonfigurasi (belum ada `firebase_options.dart`
/// hasil `flutterfire configure`) **atau** saat berjalan di platform yang tidak
/// mendukung FCM. Tujuannya mempertahankan *kontrak* yang sama dengan FCM asli
/// sehingga alur berikut tetap dapat didemonstrasikan dan diuji:
///
/// | FCM asli                      | Simulasi ini                              |
/// | ----------------------------- | ----------------------------------------- |
/// | `requestPermission()`         | meniru dialog izin, hasil bisa diatur     |
/// | `getToken()` + `POST /devices`| token fake + MockDeviceApi (sama persis)  |
/// | `onTokenRefresh`              | token fake baru → POST /devices ulang     |
/// | `onMessage` (foreground)      | `emit()` manual dari panel simulator      |
/// | `onMessageOpenedApp` (background) | `openFromBackground()`                 |
/// | `getInitialMessage()` (terminated) | `launchFromTerminated()`              |
///
/// Token palsu sengaja dibuat mirip format FCM asli (`fcm_sim_…`) dan **hanya
/// ditampilkan terpotong** lewat [shortToken] — sesuai aturan modul.
class DemoPushService implements PushService {
  DemoPushService({DeviceApi? deviceApi}) : deviceApi = deviceApi ?? MockDeviceApi();

  final DeviceApi deviceApi;
  final _messageController = StreamController<PushMessage>.broadcast();
  final _openedController = StreamController<PushMessage>.broadcast();
  final _tokenRefreshController = StreamController<String>.broadcast();

  PushPermission _permission = PushPermission.unknown;
  String? _token;
  String? _topic;
  bool _disposed = false;

  /// Acak untuk segmen token tiruan (bukan token kriptografis).
  static final Random _random = Random();
  static const _alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';

  /// Apakah izin sudah diberikan pengguna (bisa diatur lewat [requestPermission]).
  bool get permissionGranted => _permission == PushPermission.granted;

  @override
  PushBackend get backend => PushBackend.demo;

  @override
  Stream<PushMessage> get onMessage => _messageController.stream;

  @override
  Stream<PushMessage> get onMessageOpenedApp => _openedController.stream;

  @override
  Stream<String> get onTokenRefresh => _tokenRefreshController.stream;

  @override
  Future<PushMessage?> getInitialMessage() async => _initialMessage;
  PushMessage? _initialMessage;

  @override
  Future<PushPermission> requestPermission() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    // Simulator: izin diberikan agar alur bisa dilanjutkan.
    _permission = PushPermission.granted;
    return _permission;
  }

  @override
  Future<String?> getToken({
    required Future<void> Function(String token) onRegister,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _token ??= _mintToken();
    // Sama dengan FCM asli: token dikirim ke backend saat juga.
    await onRegister(_token!);
    return _token;
  }

  /// Memicu rotasi token persis seperti `onTokenRefresh` di FCM.
  ///
  /// Dalam FCM rotasi terjadi otomatis (reinstall, clear data, rotasi
  /// keamanan). Simulator mengeksposnya sebagai aksi manual agar bisa
  /// didokumentasikan.
  Future<String> rotateToken({
    required Future<void> Function(String token) onRegister,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _token = _mintToken();
    _tokenRefreshController.add(_token!);
    await onRegister(_token!);
    return _token!;
  }

  @override
  Future<void> subscribeToTopic(String topic) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    _topic = topic;
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (_topic == topic) _topic = null;
  }

  String? get currentTopic => _topic;

  @override
  Future<void> showForegroundBanner(PushMessage message) async {
    // Banner foreground di platform tanpa local notification ditangani UI
    // in-app; service cukup meneruskan pesan.
    if (!_messageController.isClosed) _messageController.add(message);
  }

  /// Kirim pesan seolah-olah diterima saat aplikasi terbuka (foreground).
  void emit(PushMessage message) {
    if (_disposed) return;
    _messageController.add(message);
  }

  /// Kirim pesan yang "diklik" dari notification tray (background).
  void openFromBackground(PushMessage message) {
    if (_disposed) return;
    _openedController.add(message);
  }

  /// Aplikasi dibuka langsung dari notifikasi (terminated).
  void launchFromTerminated(PushMessage message) {
    _initialMessage = message;
    _openedController.add(message);
  }

  String _mintToken() {
    // Segmen acak diletakkan di DEPAN supaya potongan 12 karakter yang tampil
    // di UI benar-benar berubah saat rotasi — bukti visual yang mudah dibaca.
    // Token palsu ini tidak pernah dikirim ke mana pun selain MockDeviceApi.
    final rand = List.generate(6, (_) => _alphabet[_random.nextInt(36)]).join();
    final stamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    return 'fcm_sim_${rand}_$stamp'
        '_abcdefghijklmnopqrstuvwxyz0123456789';
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await _messageController.close();
    await _openedController.close();
    await _tokenRefreshController.close();
  }
}
