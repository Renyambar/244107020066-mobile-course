import '../../../../core/failures.dart';
import '../../../../core/format.dart';
import '../../domain/repositories/device_registry.dart';

/// Backend simulasi pendaftaran perangkat (default).
///
/// Menyimpan token **hanya di memori** (tidak persisten, tidak dikirim ke mana
/// pun) dan mencatat setiap panggilan ke [log] supaya bisa dibuktikan di UI
/// bahwa `getToken` dan `onTokenRefresh` memakai jalur pendaftaran yang sama.
///
/// Penggantian ke backend HTTP cukup dengan mengimplementasikan
/// [DeviceRegistry] lain (mis. `POST /devices` via Dio) lalu menukarnya di
/// provider — presentation tidak berubah.
class MockDeviceRegistry implements DeviceRegistry {
  final List<String> log = <String>[];
  String? lastToken;

  @override
  Future<Result<String>> register(String fcmToken) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    lastToken = fcmToken;
    // Token tidak pernah disimpan/dikirim penuh — hanya potongan aman.
    final line = 'POST /devices <- ${shortToken(fcmToken)}';
    log.add(line);
    return success(line);
  }

  String get lastLog => log.isEmpty ? '-' : log.last;
}
