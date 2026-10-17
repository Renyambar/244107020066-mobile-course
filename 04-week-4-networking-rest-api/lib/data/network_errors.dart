import 'package:dio/dio.dart';

/// Refactoring Challenge #2 — memindahkan `friendlyErrorMessage` ke file
/// tersendiri (`lib/data/network_errors.dart`) agar dapat dipakai ulang oleh
/// halaman daftar penuh, halaman paginated, dan halaman detail tanpa
/// menduplikasi kode.
///
/// Setiap tipe [DioExceptionType] dipetakan ke pesan yang bisa dimengerti
/// pengguna awam (bukan teks teknis mentah seperti
/// `Connection refused (OS Error: errno = 111)`).
String friendlyErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi lambat atau timeout. Periksa internet Anda lalu coba lagi.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Periksa internet Anda.';
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == 404) return 'Data tidak ditemukan (404).';
        if (code == 401 || code == 403) {
          return 'Akses ditolak ($code). Periksa kredensial Anda.';
        }
        return 'Server bermasalah ($code). Coba lagi nanti.';
      default:
        return 'Terjadi kesalahan jaringan. Coba lagi.';
    }
  }
  return 'Terjadi kesalahan tak terduga: $error';
}
