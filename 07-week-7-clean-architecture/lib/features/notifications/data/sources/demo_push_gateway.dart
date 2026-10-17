import 'dart:async';
import 'dart:math';

import '../../domain/entities/push_message.dart';
import '../../domain/repositories/push_gateway.dart';

/// Implementasi simulasi (simulator) layanan push.
///
/// Dipakai sebagai backend default agar alur berikut tetap bisa didemonstrasikan
/// dan diuji **tanpa** kredensial Firebase:
///
/// | FCM asli                        | Simulator ini                         |
/// | ------------------------------- | ------------------------------------- |
/// | `requestPermission()`           | meniru dialog izin (hasil: granted)   |
/// | `getToken()` + `POST /devices`  | token fake + `MockDeviceRegistry`     |
/// | `onTokenRefresh`                | `rotateToken()` -> token baru         |
/// | `onMessage` (foreground)        | `emit()` dari panel simulator         |
/// | `onMessageOpenedApp` (background)| `openFromBackground()`               |
/// | `getInitialMessage()` (terminated)| `launchFromTerminated()`            |
///
/// Token palsu sengaja dibuat mirip format FCM (`fcm_sim_…`) dan **hanya**
/// ditampilkan terpotong lewat `shortToken` — sesuai aturan modul.
class DemoPushGateway implements PushGateway {
  final _messageController = StreamController<PushMessage>.broadcast();
  final _openedController = StreamController<PushMessage>.broadcast();
  final _tokenRefreshController = StreamController<String>.broadcast();

  PushPermission _permission = PushPermission.unknown;
  String? _token;
  String? _topic;
  PushMessage? _initialMessage;
  bool _disposed = false;

  static final Random _random = Random();
  static const _alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';

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

  @override
  Future<PushPermission> requestPermission() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _permission = PushPermission.granted;
    return _permission;
  }

  @override
  Future<String?> getToken() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _token ??= _mintToken();
    return _token;
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
  bool get permissionGranted => _permission == PushPermission.granted;

  // ---------------------------------------------------------------------------
  // Kontrol simulator (di luar interface PushGateway) — dipanggil lewat
  // pembungkus closure pada lapisan presentation, bukan dari widget langsung.
  // ---------------------------------------------------------------------------

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

  /// Simulasikan aplikasi dibuka langsung dari notifikasi (terminated):
  /// cukup menyimpan pesan awal yang nanti dibaca via [getInitialMessage].
  void launchFromTerminated(PushMessage message) {
    _initialMessage = message;
  }

  /// Memicu rotasi token persis seperti `onTokenRefresh` di FCM.
  Future<String> rotateToken() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _token = _mintToken();
    if (!_tokenRefreshController.isClosed) {
      _tokenRefreshController.add(_token!);
    }
    return _token!;
  }

  String _mintToken() {
    // Segmen acak di DEPAN supaya potongan 12 karakter yang tampil di UI
    // benar-benar berubah saat rotasi — bukti visual yang mudah dibaca.
    final rand = List.generate(6, (_) => _alphabet[_random.nextInt(36)]).join();
    final stamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    return 'fcm_sim_${rand}_${stamp}_abcdefghijklmnopqrstuvwxyz0123456789';
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await _messageController.close();
    await _openedController.close();
    await _tokenRefreshController.close();
  }
}
