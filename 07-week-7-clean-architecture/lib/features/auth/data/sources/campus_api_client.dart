import 'package:dio/dio.dart';

import '../../domain/repositories/session_store.dart';

/// Membangun [Dio] dengan interceptor refresh token otomatis.
///
/// Alur 401:
/// ```text
/// request -> 401? -> tukar refresh -> retry request yang sama SATU KALI
///                          |
///                 refresh gagal -> store.clear() -> logout paksa
/// ```
/// Interceptor memakai penanda `X-Auth-Retry` sehingga request yang sudah
/// pernah diretry tidak di-refresh-ulang (mencegah loop 401 tak berujung).
///
/// File ini ada di lapisan `data` — `Dio` tidak pernah dipakai presentation.
Dio buildCampusApiClient({
  required SessionStore store,
  required Future<String> Function(String refreshToken) refresh,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://example-campus-api.test',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  const retriedFlag = 'X-Auth-Retry';

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final access = await store.readAccess();
        if (access != null) {
          options.headers['Authorization'] = 'Bearer $access';
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        final alreadyRetried =
            e.requestOptions.headers.containsKey(retriedFlag);
        if (e.response?.statusCode == 401 && !alreadyRetried) {
          final token = await store.readRefresh();
          if (token == null || token.isEmpty) {
            await store.clear();
            return handler.next(e);
          }
          try {
            final renewed = await refresh(token);
            await store.save(access: renewed, refresh: token);
            // Ulangi request yang sama persis, satu kali saja.
            final options = e.requestOptions
              ..headers['Authorization'] = 'Bearer $renewed'
              ..headers[retriedFlag] = '1';
            final retry = await dio.fetch<dynamic>(options);
            return handler.resolve(retry);
          } catch (_) {
            // Refresh ikut mati -> paksa login ulang.
            await store.clear();
          }
        }
        handler.next(e);
      },
    ),
  );
  return dio;
}

/// Pemetaan `DioException` -> pesan ramah pengguna.
///
/// Hasilnya dibungkus [NetworkFailure] oleh repository; UI hanya menerima
/// `message`, bukan exception mentah.
String apiErrorMessage(Object error) {
  if (error is! DioException) return 'Terjadi kesalahan tak terduga.';

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return 'Koneksi terlalu lama. Periksa jaringan Anda.';
    case DioExceptionType.badCertificate:
      return 'Sertifikat keamanan tidak valid.';
    case DioExceptionType.connectionError:
      return 'Tidak dapat terhubung ke server. Coba lagi nanti.';
    case DioExceptionType.badResponse:
      final status = error.response?.statusCode;
      if (status == 401) return 'Sesi Anda berakhir. Silakan masuk kembali.';
      if (status == 403) return 'Anda tidak punya akses ke data ini.';
      if (status == 404) return 'Data tidak ditemukan.';
      if (status != null && status >= 500) {
        return 'Server sedang bermasalah. Coba lagi nanti.';
      }
      return 'Permintaan ditolak (HTTP $status).';
    case DioExceptionType.cancel:
      return 'Permintaan dibatalkan.';
    case DioExceptionType.unknown:
      return 'Tidak dapat terhubung. Periksa koneksi internet Anda.';
  }
}
