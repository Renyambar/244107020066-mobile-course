import 'package:dio/dio.dart';

/// Pemetaan `DioException` -> pesan ramah pengguna (Refactoring Challenge #3).
///
/// UI hanya menerima String pesan, bukan exception mentah, sehingga tidak ada
/// widget yang menguraikan `DioException.type` atau kode status sendiri-sendiri.
String apiErrorMessage(Object error) {
  if (error is AuthExceptionMessage) return error.message;
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
      if (status == 401) {
        return 'Sesi Anda berakhir. Silakan masuk kembali.';
      }
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

/// Exception ringan berisi pesan yang sudah layak tampil di UI.
class AuthExceptionMessage implements Exception {
  const AuthExceptionMessage(this.message);
  final String message;

  @override
  String toString() => message;
}
