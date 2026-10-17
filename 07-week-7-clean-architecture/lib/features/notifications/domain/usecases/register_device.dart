import '../../../../core/failures.dart';
import '../repositories/device_registry.dart';

/// Satu operasi bisnis: **daftarkan token perangkat** ke backend.
///
/// Memiliki aturan validasi (token tidak boleh kosong) sehingga dibungkus use
/// case, bukan dipanggil langsung dari notifier — sekaligus menjadi contoh kecil
/// yang mudah diuji dengan registry palsu tanpa jaringan.
class RegisterDevice {
  const RegisterDevice(this._registry);

  final DeviceRegistry _registry;

  /// Mengembalikan baris log konfirmasi (mis. `POST /devices <- fcm_sim_…`).
  Future<Result<String>> call(String fcmToken) async {
    final trimmed = fcmToken.trim();
    if (trimmed.isEmpty) {
      return failure(const ValidationFailure('Token perangkat kosong'));
    }
    return _registry.register(trimmed);
  }
}
