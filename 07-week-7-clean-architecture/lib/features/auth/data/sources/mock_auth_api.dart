/// Backend autentikasi simulasi (mock) untuk codelab tanpa server sungguhan.
///
/// Metode mengembalikan **JSON mentah** seolah respons HTTP, sehingga pemetaan
/// JSON -> entity benar-benar terjadi di model (`AuthSessionModel`), bukan di
/// domain. Titik ganti ke Firebase Auth cukup dengan mengganti isi [login]
/// dengan `signInWithEmailAndPassword`; pola repository & use case tidak berubah.
class MockAuthApi {
  /// Delay agar state loading terlihat nyata di UI.
  Duration get loginLatency => const Duration(milliseconds: 500);

  /// Respons `POST /auth/login` (bentuk dictionary JSON).
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(loginLatency);
    // Server juga memvalidasi (defense-in-depth) — aturan utama di use case.
    if (!email.contains('@') || password.length < 6) {
      throw const AuthApiException('Email atau kata sandi tidak valid');
    }
    // Simulasi JWT: header.payload.signature.
    // JANGAN parse/verifikasi JWT manual di produksi — verifikasi di server.
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final handle = email.split('@').first;
    return <String, dynamic>{
      'access': 'mock-access-$stamp-$handle',
      'refresh': 'mock-refresh-$stamp-$handle',
    };
  }

  /// Tukar [refreshToken] lama dengan access token baru.
  Future<String> refresh(String refreshToken) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (refreshToken.isEmpty) {
      throw const AuthApiException('Refresh token hilang');
    }
    return 'mock-access-renewed-${DateTime.now().millisecondsSinceEpoch}';
  }
}

/// Exception internal lapisan data (dipetakan menjadi [Failure] oleh repository).
class AuthApiException implements Exception {
  const AuthApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
