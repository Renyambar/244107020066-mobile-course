import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/auth/domain/entities/auth_session.dart';
import 'package:campus_notify/features/auth/domain/repositories/auth_repository.dart';
import 'package:campus_notify/features/auth/domain/repositories/session_store.dart';
import 'package:campus_notify/features/auth/domain/usecases/login.dart';

// --- Repository & store palsu (tanpa jaringan maupun secure storage) -------

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.fail = false});

  final bool fail;

  @override
  Future<Result<AuthSession>> login({
    required String email,
    required String password,
  }) async {
    if (fail) return failure(const AuthFailure('Email atau kata sandi tidak valid'));
    return success(AuthSession(access: 'acc-$email', refresh: 'ref-$email'));
  }

  @override
  Future<Result<CampusProfile>> fetchProfile() async => success(
        const CampusProfile(name: 'Reny', nim: '244107020066', kelas: 'TI-3F'),
      );
}

class FakeSessionStore implements SessionStore {
  String? access;
  String? refresh;
  bool cleared = false;

  @override
  Future<void> save({required String access, required String refresh}) async {
    this.access = access;
    this.refresh = refresh;
  }

  @override
  Future<void> saveAccess(String access) async => this.access = access;

  @override
  Future<String?> readAccess() async => access;

  @override
  Future<String?> readRefresh() async => refresh;

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
    cleared = true;
  }
}

void main() {
  test('Login sukses: validasi lolos, autentikasi, dan sesi tersimpan', () async {
    final store = FakeSessionStore();
    final login = Login(FakeAuthRepository(), store);

    final result = await login(
      email: '  DEMO@Kampus.test ',
      password: 'rahasia123',
    );

    expect(result.failure, isNull);
    // Email ternormalisasi (trim + lowercase) sebelum dikirim ke repository.
    expect(result.value!.access, 'acc-demo@kampus.test');
    // Sesi benar-benar disimpan lewat SessionStore (dependency inversion).
    expect(store.access, 'acc-demo@kampus.test');
    expect(store.refresh, 'ref-demo@kampus.test');
  });

  test('Login gagal validasi: email tanpa @ menghasilkan ValidationFailure',
      () async {
    final store = FakeSessionStore();
    final login = Login(FakeAuthRepository(), store);

    final result = await login(email: 'tanpa-domain', password: 'rahasia123');

    expect(result.failure, isA<ValidationFailure>());
    expect(result.value, isNull);
    expect(store.access, isNull, reason: 'sesi tidak boleh tersimpan saat gagal');
  });

  test('Login gagal validasi: sandi kurang dari 6 karakter', () async {
    final login = Login(FakeAuthRepository(), FakeSessionStore());

    final result = await login(email: 'a@b.com', password: '123');

    expect(result.failure, isA<ValidationFailure>());
    expect(result.failure!.message, contains('6 karakter'));
  });

  test('Login meneruskan failure autentikasi dari repository tanpa melempar',
      () async {
    final store = FakeSessionStore();
    final login = Login(FakeAuthRepository(fail: true), store);

    final result = await login(email: 'a@b.com', password: 'rahasia123');

    expect(result.failure, isA<AuthFailure>());
    expect(store.access, isNull);
  });
}
