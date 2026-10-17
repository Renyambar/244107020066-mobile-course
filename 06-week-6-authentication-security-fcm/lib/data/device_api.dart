import 'package:dio/dio.dart';

/// Kontrak pendaftaran perangkat ke backend (`docs/device_endpoint.md`).
///
/// Alur wajib modul: token FCM diambil via `getToken()` lalu dikirim ke sini.
/// Listener `onTokenRefresh` memanggil method yang **sama**, sehingga backend
/// selalu menyimpan token terbaru (bukan token basi).
abstract class DeviceApi {
  Future<void> registerDevice({required String fcmToken});
}

/// Implementasi untuk backend produksi: `POST /devices`.
class RemoteDeviceApi implements DeviceApi {
  RemoteDeviceApi(this._dio);
  final Dio _dio;

  @override
  Future<void> registerDevice({required String fcmToken}) async {
    await _dio.post<dynamic>(
      '/devices',
      data: {'fcm_token': fcmToken, 'platform': 'android'},
    );
  }
}

/// Backend simulasi dipakai saat Firebase/`/devices` belum tersedia.
///
/// Menyimpan token **hanya di memori** (tidak persisten, tidak dikirim ke mana
/// pun) dan mencatat setiap panggilan ke [log] supaya bisa dibuktikan di UI
/// bahwa `getToken` dan `onTokenRefresh` memakai jalur yang sama.
class MockDeviceApi implements DeviceApi {
  final List<String> log = <String>[];
  String? lastToken;

  @override
  Future<void> registerDevice({required String fcmToken}) async {
    lastToken = fcmToken;
    log.add('POST /devices <- ${shortToken(fcmToken)}');
  }

  String get lastLog => log.isEmpty ? '-' : log.last;
}

/// Potongan token yang aman ditampilkan: 12 karakter pertama + elipsis.
///
/// Token penuh tidak pernah masuk UI/screenshot (permintaan modul).
String shortToken(String token) {
  if (token.length <= 12) return token;
  return '${token.substring(0, 12)}…';
}
