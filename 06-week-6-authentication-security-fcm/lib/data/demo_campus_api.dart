import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'api_client.dart';
import 'auth_repository.dart';
import 'token_store.dart';

/// API kampus simulasi untuk mendemonstrasikan interceptor refresh 401.
///
/// `GET /me` dirancang menolak **sekali** dengan 401 (dianggap access token
/// kedaluwarsa). Interceptor pada [buildApiClient] menangkap 401, menukar
/// refresh token, lalu mengulangi request yang sama — kali ini server simulasi
/// menjawab 200. Jadi yang diuji adalah kode interceptor produksi yang asli,
/// bukan salinan logika.
///
/// **Mengapa memakai [HttpClientAdapter], bukan interceptor tambahan?**
/// Menumpuk interceptor "server tiruan" di atas interceptor auth ternyata tidak
/// memicu `onError` interceptor auth (perilaku Dio 5.11), sehingga 401 tidak
/// pernah sampai ke logika refresh. Dengan adapter, request melewati
/// interceptor persis seperti jalur produksi lalu baru disintesis di lapisan
/// transport — jadi yang diuji benar-benar kode asli.
Dio buildDemoCampusApi(TokenStore store, AuthRepository auth) {
  final dio = buildApiClient(store, auth);
  dio.httpClientAdapter = _DemoCampusServer();
  return dio;
}

/// Server kampus tiruan: menolak `GET /me` sekali (401), lalu menerima.
class _DemoCampusServer implements HttpClientAdapter {
  int _secureCalls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path != '/me') {
      return _json(404, {'error': 'not_found'});
    }

    _secureCalls++;
    if (_secureCalls == 1) {
      // Access token dianggap kedaluwarsa.
      return _json(401, {'error': 'access_token_expired'});
    }
    // Sudah diganti interceptor: server menerima.
    return _json(200, {
      'name': 'Reny Ambarwati',
      'nim': '244107020066',
      'kelas': 'TI-3F',
    });
  }

  @override
  void close({bool force = false}) {}

  ResponseBody _json(int status, Map<String, dynamic> body) =>
      ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
}
