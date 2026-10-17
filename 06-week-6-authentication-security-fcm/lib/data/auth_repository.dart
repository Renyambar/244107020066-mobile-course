/// Sesi autentikasi hasil login: sepasang token.
class AuthSession {
  const AuthSession({required this.access, required this.refresh});

  final String access;
  final String refresh;
}

/// Repository autentikasi (modul langkah 2).
///
/// Saat ini memakai **mock provider + JWT simulasi** agar codelab bisa jalan
/// tanpa backend. Titik ganti ke Firebase Auth ada di [login]: cukup ganti
/// isi method dengan `FirebaseAuth.instance.signInWithEmailAndPassword` /
/// `signInWithGoogle`. Pola repository dan refresh token-nya identik, jadi
/// migrasi tidak menyentuh UI sama sekali.
class AuthRepository {
  /// Delay agar state loading terlihat nyata di UI.
  Duration get loginLatency => const Duration(milliseconds: 500);

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(loginLatency);
    if (!email.contains('@') || password.length < 6) {
      throw const AuthException('Email atau kata sandi tidak valid');
    }
    // Simulasi JWT: header.payload.signature.
    // JANGAN parse/verifikasi JWT manual di produksi — verifikasi di server.
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return AuthSession(
      access: 'mock-access-$stamp-${email.split('@').first}',
      refresh: 'mock-refresh-$stamp-${email.split('@').first}',
    );
  }

  /// Tukar [refreshToken] lama dengan access token baru.
  Future<String> refresh(String refreshToken) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (refreshToken.isEmpty) {
      throw const AuthException('Refresh token hilang');
    }
    return 'mock-access-renewed-${DateTime.now().millisecondsSinceEpoch}';
  }
}

/// Exception autentikasi dengan pesan yang aman ditampilkan ke pengguna.
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
