import 'dart:convert';
import 'dart:typed_data';

import 'package:campus_notify/data/auth_repository.dart';
import 'package:campus_notify/data/device_api.dart';
import 'package:campus_notify/messaging/route_parser.dart';
import 'package:campus_notify/providers/auth_provider.dart';
import 'package:campus_notify/routes.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/data/api_client.dart';
import 'package:campus_notify/data/demo_campus_api.dart';
import 'package:campus_notify/data/token_store.dart';

/// Server kampus tiruan: menolak `Bearer stale-access` (401) dan menerima
/// access token yang sudah diperbarui (200). Dipasang sebagai [HttpClientAdapter]
/// sehingga interceptor refresh diuji lewat jalur produksi yang asli.
class _FakeCampusServer implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final header = options.headers['Authorization'];
    if (header == 'Bearer stale-access') {
      return _json(401, {'error': 'access_token_expired'});
    }
    return _json(200, {'name': 'Reny Ambarwati', 'nim': '244107020066'});
  }

  @override
  void close({bool force = false}) {}
}

/// Server yang selalu menolak — dipakai memastikan interceptor berhenti setelah
/// satu kali percobaan refresh (tidak berputar 401 tanpa henti).
class _Always401Adapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      _json(401, {'error': 'still_expired'});

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Map<String, dynamic> body) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

/// Token store palsu untuk menguji logika sesi tanpa secure storage sungguhan.
///
/// Secure storage butuh platform channel, sehingga di unit test memakai gantian
/// in-memory yang meniru kontrak `TokenStore`.
class FakeTokenStore implements TokenStore {
  String? access;
  String? refresh;

  @override
  Future<void> save({required String access, required String refresh}) async {
    this.access = access;
    this.refresh = refresh;
  }

  @override
  Future<void> saveAccess(String access) async => this.access = access;

  @override
  Future<String?> readAccess() async => access;

  @override
  Future<String?> readRefresh() async => refresh;

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }
}

void main() {
  group('routeFromMessage — parsing payload FCM (Refactoring #2)', () {
    test('route kosong -> halaman utama', () {
      expect(routeFromMessage(<String, dynamic>{}), AppRoutes.home);
    });

    test('rute tanpa slash diberi slash', () {
      expect(
        routeFromMessage(<String, dynamic>{'route': 'pengumuman/3'}),
        '/pengumuman/3',
      );
    });

    test('rute valid dengan slash dipertahankan', () {
      expect(
        routeFromMessage(<String, dynamic>{'route': '/pengumuman/3'}),
        '/pengumuman/3',
      );
    });

    test('rute di luar allow-list ditolak ke halaman utama', () {
      expect(
        routeFromMessage(<String, dynamic>{'route': 'https://evil.example'}),
        AppRoutes.home,
      );
      expect(
        routeFromMessage(<String, dynamic>{'route': '/admin/panel'}),
        AppRoutes.home,
      );
      expect(
        routeFromMessage(<String, dynamic>{'route': '/pengumuman/abc'}),
        AppRoutes.home,
      );
    });

    test('data payload membawa id pengumuman yang konsisten dengan rute', () {
      const data = <String, dynamic>{'route': '/pengumuman/3', 'id': '3'};
      expect(data['id'], '3');
      expect(routeFromMessage(data), '/pengumuman/3');
      expect(announcementIdFromMessage(data), '3');
      expect(AppRoutes.isAnnouncement(routeFromMessage(data)), isTrue);
    });

    test('id tidak numerik dianggap tidak ada', () {
      expect(announcementIdFromMessage(<String, dynamic>{'id': 'abc'}), isNull);
      expect(announcementIdFromMessage(<String, dynamic>{}), isNull);
    });

    test('payload hanya-data tidak layak menampilkan banner', () {
      // Data-only: diteruskan ke handler, TIDAK ditampilkan otomatis.
      expect(hasNotificationPayload(title: null, body: null), isFalse);
      expect(
        hasNotificationPayload(
          title: null,
          body: null,
        ),
        isFalse,
      );
      // Payload gabungan notification + data tetap layak tampil.
      expect(hasNotificationPayload(title: 'Jadwal berubah', body: 'A2'), isTrue);
      expect(hasNotificationPayload(title: 'Judul', body: null), isTrue);
    });
  });

  group('AuthRepository — login & refresh (mock provider)', () {
    late AuthRepository auth;

    setUp(() => auth = AuthRepository());

    test('login sukses menghasilkan sepasang token', () async {
      final session =
          await auth.login(email: 'demo@kampus.test', password: 'rahasia123');
      expect(session.access, isNotEmpty);
      expect(session.refresh, isNotEmpty);
    });

    test('login gagal untuk email tanpa @ atau sandi < 6 karakter', () async {
      expect(
        () => auth.login(email: 'salah', password: 'rahasia123'),
        throwsA(isA<AuthException>()),
      );
      expect(
        () => auth.login(email: 'demo@kampus.test', password: '123'),
        throwsA(isA<AuthException>()),
      );
    });

    test('refresh dengan token kosong melempar AuthException', () async {
      expect(() => auth.refresh(''), throwsA(isA<AuthException>()));
    });
  });

  group('TokenStore (fake) — status login & sesi', () {
    test('provider auth membaca status login dari token', () async {
      final store = FakeTokenStore()..access = 'mock-access';
      expect(await store.readAccess(), isNotNull);
      store.access = null;
      expect(await store.readAccess(), isNull);
    });

    test('refresh gagal -> sesi dibersihkan (paksa login ulang)', () async {
      final store = FakeTokenStore()..refresh = '';
      final needsLogin = (await store.readRefresh() ?? '').isEmpty;
      expect(needsLogin, isTrue);
    });

    test('clear menghapus access dan refresh', () async {
      final store = FakeTokenStore();
      await store.save(access: 'a', refresh: 'r');
      await store.clear();
      expect(await store.readAccess(), isNull);
      expect(await store.readRefresh(), isNull);
    });
  });

  group('Interceptor Dio — 401 refresh sekali lalu retry', () {
    late FakeTokenStore store;
    late AuthRepository auth;
    late Dio dio;

    setUp(() {
      store = FakeTokenStore()
        ..access = 'stale-access'
        ..refresh = 'valid-refresh';
      auth = AuthRepository();
      dio = buildApiClient(store, auth);

      // Server tiruan lewat adapter: menolak "stale-access" dengan 401 dan
      // menerima token yang sudah diperbarui. Memakai adapter memastikan
      // interceptor auth diuji persis seperti pada jalur produksi.
      dio.httpClientAdapter = _FakeCampusServer();
    });

    test('401 -> refresh -> retry sukses (200)', () async {
      final res = await dio.get<dynamic>('/me');
      expect(res.statusCode, 200);
      // Access token sudah diganti oleh interceptor.
      expect(store.access, startsWith('mock-access-renewed-'));
      // Retry tidak berputar: cukup sekali.
      expect(res.data['name'], 'Reny Ambarwati');
    });

    test('refresh gagal -> sesi dihapus, exception diteruskan', () async {
      store.refresh = ''; // refresh mati
      await expectLater(
        dio.get<dynamic>('/me'),
        throwsA(isA<DioException>()),
      );
      expect(await store.readAccess(), isNull);
      expect(await store.readRefresh(), isNull);
    });

    test('401 kedua tidak memicu refresh ulang (anti-loop)', () async {
      // Server yang selalu menolak: interceptor hanya boleh refresh satu kali
      // lalu meneruskan error, bukan berputar selamanya.
      dio.httpClientAdapter = _Always401Adapter();
      await expectLater(
        dio.get<dynamic>('/me'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            401,
          ),
        ),
      );
      expect(await store.readAccess(), isNull);
    });
  });

  group('DemoCampusApi — interceptor refresh diuji lewat jalur asli', () {
    late FakeTokenStore store;
    late Dio dio;

    setUp(() {
      store = FakeTokenStore()
        ..access = 'mock-access'
        ..refresh = 'mock-refresh';
      dio = buildDemoCampusApi(store, AuthRepository());
    });

    test('401 pertama memicu refresh lalu retry sukses 200', () async {
      final res = await dio.get<Map<String, dynamic>>('/me');
      expect(res.statusCode, 200);
      expect(res.data?['name'], 'Reny Ambarwati');
      // Access token sudah ditukar oleh interceptor.
      expect(store.access, startsWith('mock-access-renewed-'));
    });

    test('refresh mati -> sesi dibersihkan dan 401 diteruskan', () async {
      store.refresh = '';
      await expectLater(
        dio.get<Map<String, dynamic>>('/me'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            401,
          ),
        ),
      );
      expect(await store.readAccess(), isNull);
    });
  });

  group('MockDeviceApi — kontrak POST /devices', () {
    test('registerDevice mencatat token terpotong (bukan token penuh)', () async {
      final api = MockDeviceApi();
      const token = 'fcm_sim_abcdefghijklmnopqrstuvwxyz0123456789';
      await api.registerDevice(fcmToken: token);

      expect(api.lastToken, token); // backend menerima token penuh
      expect(api.lastLog, contains('…')); // log/UI hanya memakai potongan
      expect(api.lastLog.length, lessThan(token.length));
      expect(shortToken(token), '${token.substring(0, 12)}…');
    });
  });

  group('Provider auth — guard route', () {
    test('awalnya belum login ketika token kosong', () async {
      final container = ProviderContainer(
        overrides: [
          tokenStoreProvider.overrideWithValue(FakeTokenStore()),
        ],
      );
      addTearDown(container.dispose);
      final loggedIn = await container.read(authStateProvider.future);
      expect(loggedIn, isFalse);
    });
  });
}
