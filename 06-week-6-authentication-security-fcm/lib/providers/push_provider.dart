import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/device_api.dart';
import '../messaging/demo_push_service.dart';
import '../messaging/push_service.dart';
import '../messaging/route_parser.dart';

/// Instance layanan push — di-override saat startup oleh `main()`.
final pushServiceProvider = Provider<PushService>(
  (ref) => throw UnimplementedError('Di-override di main()'),
);

/// Dio untuk pendaftaran perangkat (`POST /devices`).
final deviceDioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example-campus-api.test'));
  return dio;
});

/// Backend pendaftaran perangkat. Default: simulasi (lihat `docs/device_endpoint.md`).
final deviceApiProvider = Provider<DeviceApi>((ref) {
  return MockDeviceApi();
});

/// State lengkap layanan push yang dipantau UI.
class PushState {
  const PushState({
    this.backend = PushBackend.demo,
    this.permission = PushPermission.unknown,
    this.token,
    this.topic,
    this.subscribed = false,
    this.registered = false,
    this.lastDeviceLog = '-',
    this.events = const [],
  });

  final PushBackend backend;
  final PushPermission permission;
  final String? token;
  final String? topic;
  final bool subscribed;
  final bool registered;
  final String lastDeviceLog;
  final List<String> events;

  PushState copyWith({
    PushBackend? backend,
    PushPermission? permission,
    String? token,
    String? topic,
    bool? subscribed,
    bool? registered,
    String? lastDeviceLog,
    List<String>? events,
  }) =>
      PushState(
        backend: backend ?? this.backend,
        permission: permission ?? this.permission,
        token: token ?? this.token,
        topic: topic ?? this.topic,
        subscribed: subscribed ?? this.subscribed,
        registered: registered ?? this.registered,
        lastDeviceLog: lastDeviceLog ?? this.lastDeviceLog,
        events: events ?? this.events,
      );

  bool get isRealFcm => backend == PushBackend.fcm;
}

class PushNotifier extends Notifier<PushState> {
  StreamSubscription<String>? _tokenSub;
  final List<String> _events = [];

  @override
  PushState build() {
    final service = ref.read(pushServiceProvider);
    // Rotasi token: kirim token BARU ke backend, jangan hanya dicetak.
    _tokenSub = service.onTokenRefresh.listen((token) {
      _events.insert(0, 'onTokenRefresh -> POST /devices (${shortToken(token)})');
      _register(token);
      state = state.copyWith(
        token: shortToken(token),
        events: List.unmodifiable(_events),
      );
    });
    ref.onDispose(() => _tokenSub?.cancel());
    return PushState(backend: service.backend);
  }

  /// Minta izin notifikasi (Android 13+ / iOS / Web wajib runtime permission).
  Future<void> requestPermission() async {
    final service = ref.read(pushServiceProvider);
    final permission = await service.requestPermission();
    _events.insert(0, 'requestPermission -> ${permission.name}');
    state = state.copyWith(
      permission: permission,
      events: List.unmodifiable(_events),
    );
  }

  /// Ambil registration token lalu kirimkan ke backend (`POST /devices`).
  Future<void> fetchToken() async {
    final service = ref.read(pushServiceProvider);
    final token = await service.getToken(onRegister: _register);
    _events.insert(0, 'getToken -> ${token == null ? 'null' : shortToken(token)}');
    state = state.copyWith(
      token: token == null ? null : shortToken(token),
      registered: token != null,
      events: List.unmodifiable(_events),
    );
  }

  /// Rotasi token (simulasi `onTokenRefresh` — aslinya terjadi otomatis).
  Future<void> rotateToken() async {
    final service = ref.read(pushServiceProvider);
    if (service is DemoPushService) {
      final token = await service.rotateToken(onRegister: _register);
      state = state.copyWith(token: shortToken(token), registered: true);
      return;
    }
    // FCM asli: minta token baru; listener onTokenRefresh yang mengirim ulang.
    final token = await service.getToken(onRegister: _register);
    state = state.copyWith(token: token == null ? null : shortToken(token));
  }

  Future<void> subscribeTopic(String topic) async {
    final service = ref.read(pushServiceProvider);
    await service.subscribeToTopic(topic);
    _events.insert(0, 'subscribeToTopic("$topic")');
    state = state.copyWith(
      subscribed: true,
      topic: topic,
      events: List.unmodifiable(_events),
    );
  }

  Future<void> unsubscribeTopic(String topic) async {
    final service = ref.read(pushServiceProvider);
    await service.unsubscribeFromTopic(topic);
    _events.insert(0, 'unsubscribeFromTopic("$topic")');
    state = state.copyWith(
      subscribed: false,
      events: List.unmodifiable(_events),
    );
  }

  /// Catat penerimaan pesan foreground ke log UI.
  void logForeground(PushMessage message) {
    _events.insert(0, 'onMessage (foreground) -> ${routeFromMessage(message.data)}');
    if (_events.length > 8) _events.removeRange(8, _events.length);
    state = state.copyWith(events: List.unmodifiable(_events));
  }

  /// Catat klik pesan dari background.
  void logOpenedFromBackground(String route) {
    _events.insert(0, 'onMessageOpenedApp (background) -> $route');
    if (_events.length > 8) _events.removeRange(8, _events.length);
    state = state.copyWith(events: List.unmodifiable(_events));
  }

  /// Catat pembukaan aplikasi dari notifikasi (terminated).
  void logTerminated(String route) {
    _events.insert(0, 'getInitialMessage (terminated) -> $route');
    if (_events.length > 8) _events.removeRange(8, _events.length);
    state = state.copyWith(events: List.unmodifiable(_events));
  }

  Future<void> _register(String token) async {
    await ref.read(deviceApiProvider).registerDevice(fcmToken: token);
    state = state.copyWith(
      registered: true,
      lastDeviceLog: ref.read(deviceApiProvider) is MockDeviceApi
          ? (ref.read(deviceApiProvider) as MockDeviceApi).lastLog
          : 'POST /devices <- ${shortToken(token)}',
    );
  }
}

final pushProvider = NotifierProvider<PushNotifier, PushState>(
  PushNotifier.new,
);
