import 'package:dio/dio.dart';

/// Langkah 2 codelab — Konfigurasi Dio terpusat.
///
/// Seluruh konfigurasi jaringan (base URL, timeout, header, logging) hidup
/// di satu tempat sehingga tidak tersebar di tiap method repository.
///
/// `baseUrl` bisa ditimpa lewat `--dart-define` tanpa mengubah kode,
/// sehingga skenario error (langkah "Uji tiga skenario error") dapat
/// diuji ulang secara deterministik:
///
/// ```sh
/// flutter run --dart-define=API_BASE_URL=https://jsonplaceholder.typicodex.com
/// ```
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://jsonplaceholder.typicode.com',
);

Dio createDio({String? baseUrl}) {
  final dio = Dio(
    BaseOptions(
      // Base URL dipotong trailing slash agar `get('/posts')` tidak
      // menghasilkan path ganda `//posts`.
      baseUrl: (baseUrl ?? kApiBaseUrl).replaceAll(RegExp(r'/+$'), ''),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Accept': 'application/json'},
    ),
  );

  // Interceptor logging: mempermudah memantau method, URL, query parameter,
  // dan status code setiap request selama pengembangan.
  dio.interceptors.add(
    LogInterceptor(requestBody: true, responseBody: false),
  );
  return dio;
}
