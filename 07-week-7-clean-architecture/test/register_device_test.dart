import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/notifications/domain/repositories/device_registry.dart';
import 'package:campus_notify/features/notifications/domain/usecases/register_device.dart';

// --- Registry palsu (tanpa jaringan) ---------------------------------------

class FakeDeviceRegistry implements DeviceRegistry {
  FakeDeviceRegistry({this.fail = false});

  final bool fail;
  String? lastToken;

  @override
  Future<Result<String>> register(String fcmToken) async {
    if (fail) return failure(const NetworkFailure('tidak dapat terhubung'));
    lastToken = fcmToken;
    return success('POST /devices <- $fcmToken');
  }
}

void main() {
  test('RegisterDevice sukses: token terkirim dan log dikembalikan', () async {
    final registry = FakeDeviceRegistry();

    final result = await RegisterDevice(registry)('fcm_sim_abc123');

    expect(result.failure, isNull);
    expect(registry.lastToken, 'fcm_sim_abc123');
    expect(result.value, contains('POST /devices'));
  });

  test('RegisterDevice menolak token kosong dengan ValidationFailure',
      () async {
    final registry = FakeDeviceRegistry();

    final result = await RegisterDevice(registry)('   ');

    expect(result.failure, isA<ValidationFailure>());
    expect(registry.lastToken, isNull, reason: 'registry tak boleh dipanggil');
  });

  test('RegisterDevice meneruskan failure registry tanpa melempar', () async {
    final registry = FakeDeviceRegistry(fail: true);

    final result = await RegisterDevice(registry)('fcm_sim_abc123');

    expect(result.failure, isA<NetworkFailure>());
    expect(result.value, isNull);
  });
}
