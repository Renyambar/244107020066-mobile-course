import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Server kampus tiruan yang menolak `GET /me` **sekali** dengan 401
/// (dianggap access token kedaluwarsa), lalu menerima pada percobaan berikut.
///
/// Dengan adapter ini, interceptor produksi yang asli (401 -> refresh -> retry)
/// benar-benar teruji tanpa backend sungguhan. Request melewati interceptor
/// persis seperti jalur produksi lalu disintesis di lapisan transport.
class DemoCampusServer implements HttpClientAdapter {
  int _secureCalls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path != '/me') {
      return _json(404, <String, dynamic>{'error': 'not_found'});
    }

    _secureCalls++;
    if (_secureCalls == 1) {
      // Access token dianggap kedaluwarsa.
      return _json(401, <String, dynamic>{'error': 'access_token_expired'});
    }
    // Sudah diganti interceptor: server menerima.
    return _json(200, <String, dynamic>{
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
