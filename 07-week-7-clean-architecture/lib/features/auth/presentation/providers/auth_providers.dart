import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../data/sources/mock_auth_api.dart';
import '../../data/sources/secure_session_store.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/session_store.dart';
import '../../domain/usecases/login.dart';

// ---------------------------------------------------------------------------
// Data layer: implementasi disuntikkan sekali di sini (composition point fitur).
// ---------------------------------------------------------------------------

/// Penyimpanan sesi (secure storage) — lapisan data.
final sessionStoreProvider = Provider<SessionStore>(
  (ref) => SecureSessionStore(),
);

/// Repository auth — lapisan data, dibangun dari abstraksi yang sama
/// yang dipakai domain.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    api: MockAuthApi(),
    store: ref.watch(sessionStoreProvider),
  );
});

// ---------------------------------------------------------------------------
// Domain layer: use case menerima abstraksi, bukan implementasi konkret.
// ---------------------------------------------------------------------------

final loginProvider = Provider<Login>((ref) {
  return Login(
    ref.watch(authRepositoryProvider),
    ref.watch(sessionStoreProvider),
  );
});

// ---------------------------------------------------------------------------
// Presentation layer: state yang hanya dibaca oleh widget.
// ---------------------------------------------------------------------------

/// Status login: `true` bila ada access token valid tersimpan.
final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, bool>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final token = await ref.watch(sessionStoreProvider).readAccess();
    return token != null;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    final result =
        await ref.read(loginProvider)(email: email, password: password);
    if (result.failure != null) {
      // `failure` sudah berupa pesan ramah pengguna (Failure dari domain).
      state = AsyncError(result.failure!, StackTrace.current);
    } else {
      state = const AsyncData(true);
    }
  }

  Future<void> logout() async {
    await ref.read(sessionStoreProvider).clear();
    ref.invalidateSelf();
  }
}

// ---------------------------------------------------------------------------
// Uji keamanan 401 -> refresh -> retry (repository langsung ke notifier).
// ---------------------------------------------------------------------------

/// Hasil pemeriksaan `GET /me`.
class ProfileCheck {
  const ProfileCheck({this.name, this.error, this.busy = false});

  final String? name;
  final String? error;
  final bool busy;

  bool get ok => name != null;
}

/// `fetchProfile` tidak punya aturan bisnis tambahan, jadi dipanggil langsung
/// dari repository ke notifier (tanpa use case wrapper) — sesuai panduan modul
/// tentang kapan use case tidak perlu.
class ProfileNotifier extends Notifier<ProfileCheck> {
  @override
  ProfileCheck build() => const ProfileCheck();

  Future<void> run() async {
    state = const ProfileCheck(busy: true);
    final result = await ref.read(authRepositoryProvider).fetchProfile();
    if (result.failure != null) {
      state = ProfileCheck(error: result.failure!.message);
    } else {
      state = ProfileCheck(name: result.value!.name);
    }
  }
}

final profileCheckProvider =
    NotifierProvider<ProfileNotifier, ProfileCheck>(ProfileNotifier.new);
