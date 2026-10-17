import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format.dart';
import '../../data/sources/demo_push_gateway.dart';
import '../../data/sources/mock_device_registry.dart';
import '../../domain/entities/push_message.dart';
import '../../domain/repositories/device_registry.dart';
import '../../domain/repositories/push_gateway.dart';
import '../../domain/usecases/register_device.dart';

// ---------------------------------------------------------------------------
// Data layer: gateway disuntikkan dari main(), registry & use case di sini.
// ---------------------------------------------------------------------------

/// Instance layanan push — di-override saat startup oleh `main()`
/// (lihat `data/push_bootstrap.dart`).
final pushGatewayProvider = Provider<PushGateway>(
  (ref) => throw UnimplementedError('Di-override di main()'),
);

/// Backend pendaftaran perangkat. Default: simulasi in-memory.
final deviceRegistryProvider = Provider<DeviceRegistry>(
  (ref) => MockDeviceRegistry(),
);

// ---------------------------------------------------------------------------
// Domain layer: use case menerima abstraksi.
// ---------------------------------------------------------------------------

final registerDeviceProvider = Provider<RegisterDevice>(
  (ref) => RegisterDevice(ref.watch(deviceRegistryProvider)),
);

// ---------------------------------------------------------------------------
// Presentation layer: state push yang dibaca UI.
// ---------------------------------------------------------------------------

/// Status push yang dipantau UI (view-state, bukan entitas domain).
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
    final gateway = ref.read(pushGatewayProvider);
    // Rotasi token: kirim token BARU ke backend, jangan hanya dicetak.
    _tokenSub = gateway.onTokenRefresh.listen((token) async {
      _events.insert(
        0,
        'onTokenRefresh -> POST /devices (${shortToken(token)})',
      );
      await _register(token);
      state = state.copyWith(
        token: shortToken(token),
        events: List.unmodifiable(_events),
      );
    });
    ref.onDispose(() => _tokenSub?.cancel());
    return PushState(backend: gateway.backend);
  }

  /// Minta izin notifikasi (Android 13+ / iOS / Web: runtime permission).
  Future<void> requestPermission() async {
    final permission = await ref.read(pushGatewayProvider).requestPermission();
    _events.insert(0, 'requestPermission -> ${permission.name}');
    state = state.copyWith(
      permission: permission,
      events: List.unmodifiable(_events),
    );
  }

  /// Ambil registration token lalu daftarkan ke backend (`POST /devices`).
  Future<void> fetchToken() async {
    final token = await ref.read(pushGatewayProvider).getToken();
    _events.insert(
      0,
      'getToken -> ${token == null ? 'null' : shortToken(token)}',
    );
    if (token != null) {
      await _register(token);
      state = state.copyWith(
        token: shortToken(token),
        registered: true,
        events: List.unmodifiable(_events),
      );
    } else {
      state = state.copyWith(events: List.unmodifiable(_events));
    }
  }

  Future<void> subscribeTopic(String topic) async {
    await ref.read(pushGatewayProvider).subscribeToTopic(topic);
    _events.insert(0, 'subscribeToTopic("$topic")');
    state = state.copyWith(
      subscribed: true,
      topic: topic,
      events: List.unmodifiable(_events),
    );
  }

  Future<void> unsubscribeTopic(String topic) async {
    await ref.read(pushGatewayProvider).unsubscribeFromTopic(topic);
    _events.insert(0, 'unsubscribeFromTopic("$topic")');
    state = state.copyWith(
      subscribed: false,
      events: List.unmodifiable(_events),
    );
  }

  /// Catat penerimaan pesan foreground ke log UI.
  void logForeground(PushMessage message) {
    _events.insert(0, 'onMessage (foreground) -> ${routeFromMessage(message.data)}');
    _trim();
    state = state.copyWith(events: List.unmodifiable(_events));
  }

  /// Catat klik pesan dari background.
  void logOpenedFromBackground(String route) {
    _events.insert(0, 'onMessageOpenedApp (background) -> $route');
    _trim();
    state = state.copyWith(events: List.unmodifiable(_events));
  }

  /// Catat pembukaan aplikasi dari notifikasi (terminated).
  void logTerminated(String route) {
    _events.insert(0, 'getInitialMessage (terminated) -> $route');
    _trim();
    state = state.copyWith(events: List.unmodifiable(_events));
  }

  void _trim() {
    if (_events.length > 8) _events.removeRange(8, _events.length);
  }

  Future<void> _register(String token) async {
    final result = await ref.read(registerDeviceProvider)(token);
    if (result.value != null) {
      state = state.copyWith(
        registered: true,
        lastDeviceLog: result.value!,
      );
    } else if (result.failure != null) {
      state = state.copyWith(lastDeviceLog: result.failure!.message);
    }
  }
}

final pushProvider = NotifierProvider<PushNotifier, PushState>(
  PushNotifier.new,
);

// ---------------------------------------------------------------------------
// Pembungkus simulator: menyembunyikan kelas data (DemoPushGateway) di balik
// closure, sehingga widget hanya melihat fungsi & entitas domain.
// ---------------------------------------------------------------------------

class PushSimulator {
  const PushSimulator({
    required this.emitForeground,
    required this.openFromBackground,
    required this.launchFromTerminated,
    required this.rotateToken,
  });

  final void Function(PushMessage) emitForeground;
  final void Function(PushMessage) openFromBackground;
  final void Function(PushMessage) launchFromTerminated;
  final Future<String> Function() rotateToken;
}

/// Non-null hanya saat backend aktif adalah simulator.
final pushSimulatorProvider = Provider<PushSimulator?>((ref) {
  final gateway = ref.watch(pushGatewayProvider);
  if (gateway is DemoPushGateway) {
    return PushSimulator(
      emitForeground: gateway.emit,
      openFromBackground: gateway.openFromBackground,
      launchFromTerminated: gateway.launchFromTerminated,
      rotateToken: gateway.rotateToken,
    );
  }
  return null;
});
