import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../firebase_options.dart';
import 'fcm_push_service.dart';
import 'push_service.dart';
import 'route_parser.dart';

/// Adapter [PushService] di atas Firebase Cloud Messaging (asli).
///
/// Menerjemahkan API Firebase ke kontrak netral milik aplikasi sehingga
/// lapisan UI tidak mengetahui sedang memakai FCM asli atau simulator.
class FcmPushService implements PushService {
  FcmPushService._(this._messaging);

  final FirebaseMessaging _messaging;
  StreamSubscription<RemoteMessage>? _openedSub;

  /// Inisialisasi Firebase lalu bungkus [FirebaseMessaging].
  ///
  /// Melempar [FirebaseInitializationException] bila `firebase_options.dart`
  /// belum diisi hasil `flutterfire configure`, sehingga pemanggil bisa
  /// jatuh ke [DemoPushService].
  static Future<FcmPushService> create() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on UnimplementedError {
      throw const FirebaseInitializationException(
        'firebase_options.dart belum dikonfigurasi (flutterfire configure).',
      );
    }
    return FcmPushService._(FirebaseMessaging.instance);
  }

  @override
  PushBackend get backend => PushBackend.fcm;

  final _messageController = StreamController<PushMessage>.broadcast();
  final _openedController = StreamController<PushMessage>.broadcast();

  StreamSubscription<RemoteMessage>? _messageSub;
  bool _listening = false;

  void _ensureListening() {
    if (_listening) return;
    _listening = true;
    _messageSub = FirebaseMessaging.onMessage.listen((message) {
      _messageController.add(_toPushMessage(message));
    });
    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _openedController.add(_toPushMessage(message));
    });
  }

  static PushMessage _toPushMessage(RemoteMessage message) => PushMessage(
        title: message.notification?.title,
        body: message.notification?.body,
        data: message.data,
      );

  @override
  Stream<PushMessage> get onMessage {
    _ensureListening();
    return _messageController.stream;
  }

  @override
  Stream<PushMessage> get onMessageOpenedApp {
    _ensureListening();
    return _openedController.stream;
  }

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Future<PushMessage?> getInitialMessage() async {
    final initial = await _messaging.getInitialMessage();
    return initial == null ? null : _toPushMessage(initial);
  }

  @override
  Future<PushPermission> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );
    switch (settings.authorizationStatus) {
      case AuthorizationStatus.authorized:
      case AuthorizationStatus.provisional:
        return PushPermission.granted;
      case AuthorizationStatus.denied:
      case AuthorizationStatus.deniedPermanently:
        return PushPermission.denied;
      case AuthorizationStatus.notDetermined:
        return PushPermission.unknown;
    }
  }

  @override
  Future<String?> getToken({
    required Future<void> Function(String token) onRegister,
  }) async {
    final token = await _messaging.getToken();
    if (token != null) await onRegister(token);
    return token;
  }

  @override
  Future<void> subscribeToTopic(String topic) =>
      _messaging.subscribeToTopic(topic);

  @override
  Future<void> unsubscribeFromTopic(String topic) =>
      _messaging.unsubscribeFromTopic(topic);

  @override
  Future<void> showForegroundBanner(PushMessage message) async {
    // Android/iOS: tampilkan notifikasi lokal (sistem tidak menampilkan banner
    // otomatis saat foreground). Web: tidak didukung flutter_local_notifications
    // sehingga banner ditampilkan in-app oleh UI.
    await showLocalNotificationPayload(
      title: message.title,
      body: message.body,
      route: routeFromMessage(message.data),
    );
  }

  @override
  Future<void> dispose() async {
    await _messageSub?.cancel();
    await _openedSub?.cancel();
    await _messageController.close();
    await _openedController.close();
  }

  /// Rute tujuan dari pesan ini (untuk keperluan UI).
  String routeOf(PushMessage message) => routeFromMessage(message.data);
}

/// Dilempar saat konfigurasi Firebase belum tersedia.
class FirebaseInitializationException implements Exception {
  const FirebaseInitializationException(this.message);
  final String message;

  @override
  String toString() => message;
}
