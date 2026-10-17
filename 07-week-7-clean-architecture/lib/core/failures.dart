/// Kegagalan bisnis yang ramah pengguna (domain murni Dart, tanpa Flutter).
///
/// `sealed class` membuat presentation wajib menangani tiap varian lewat
/// `switch`, dan exception mentah dari Dio/SQLite/secure storage tidak pernah
/// bocor ke UI — semua dipetakan menjadi [Failure] di lapisan data.
sealed class Failure {
  const Failure(this.message);

  /// Pesan yang layak ditampilkan ke pengguna.
  final String message;

  @override
  String toString() => message;
}

/// Kegagalan akses penyimpanan lokal (SQLite / secure storage).
class LocalFailure extends Failure {
  const LocalFailure(super.message);
}

/// Kegagalan jaringan / HTTP (timeout, 5xx, koneksi terputus).
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Kegagalan validasi input dari use case (format email, panjang sandi, id).
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Kegagalan autentikasi (kredensial ditolak, sesi kedaluwarsa).
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Hasil operasi dua arah: sukses mengisi [value], gagal mengisi [failure].
///
/// Pola *record* Dart (lihat modul bagian kontrak repository) agar sukses/gagal
/// eksplisit tanpa melempar exception ke presentation. Alternatif industri:
/// `Either<Failure, T>` dari package `fpdart`/`dartz` — pola kontraknya sama.
typedef Result<T> = ({T? value, Failure? failure});

/// Konstruktor sukses: [value] terisi, [failure] bernilai null.
Result<T> success<T>(T value) => (value: value, failure: null);

/// Konstruktor gagal: [value] bernilai null, [failure] terisi.
Result<T> failure<T>(Failure error) => (value: null, failure: error);
