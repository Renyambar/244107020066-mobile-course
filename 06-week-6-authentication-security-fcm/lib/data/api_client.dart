import 'package:dio/dio.dart';

import 'auth_repository.dart';
import 'api_errors.dart';
import 'token_store.dart';

/// Membangun [Dio] dengan interceptor refresh token otomatis (modul langkah 3).
///
/// Alur 401:
/// ```text
/// request -> 401? -> tukar refresh -> retry request yang sama SATU KALI
///                          |
///                 refresh gagal -> store.clear() -> logout paksa
/// ```
/// Interceptor memakai penanda `AuthorizationRetry` di header sehingga request
/// yang sudah pernah diretry tidak di-refresh-ulang (mencegah loop 401 tak
/// berujung).
Dio buildApiClient(TokenStore store, AuthRepository auth) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://example-campus-api.test',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  /// Header penanda: request ini sudah melewati satu kali percobaan refresh.
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
          final refresh = await store.readRefresh();
          if (refresh == null || refresh.isEmpty) {
            await store.clear();
            return handler.next(e);
          }
          try {
            final renewed = await auth.refresh(refresh);
            await store.save(access: renewed, refresh: refresh);
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

/// Konversi exception auth menjadi pesan yang layak tampil di UI.
String authErrorMessage(Object error) => apiErrorMessage(error);
