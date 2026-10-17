import '../../../../core/failures.dart';

/// Kontrak pendaftaran perangkat ke backend (`POST /devices`).
///
/// Mengembalikan baris log yang layak ditampilkan di UI (token sudah
/// dipotong), sehingga presentation tidak pernah menyusun atau memotong token
/// mentah sendiri.
abstract class DeviceRegistry {
  Future<Result<String>> register(String fcmToken);
}
