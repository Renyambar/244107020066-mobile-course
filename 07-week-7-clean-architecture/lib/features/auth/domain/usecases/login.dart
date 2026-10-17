import '../../../../core/failures.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';
import '../repositories/session_store.dart';

/// Satu operasi bisnis: **login** — validasi, normalisasi, autentikasi,
/// lalu simpan sesi.
///
/// Ini contoh klasik *kapan use case dibutuhkan* (lihat modul bagian "Kapan
/// use case perlu?"): ia **menggabungkan dua kontrak** — [AuthRepository]
/// (autentikasi) dan [SessionStore] (persistensi sesi) — plus punya aturan
/// bisnis sendiri (validasi format & normalisasi email). Bukan sekadar wrapper
/// CRUD satu baris.
class Login {
  const Login(this._repository, this._store);

  final AuthRepository _repository;
  final SessionStore _store;

  Future<Result<AuthSession>> call({
    required String email,
    required String password,
  }) async {
    // --- Aturan bisnis: validasi & normalisasi input ---
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      return failure(const ValidationFailure('Email wajib diisi'));
    }
    if (!normalizedEmail.contains('@')) {
      return failure(const ValidationFailure('Email tidak valid'));
    }
    if (password.isEmpty) {
      return failure(const ValidationFailure('Kata sandi wajib diisi'));
    }
    if (password.length < 6) {
      return failure(const ValidationFailure('Kata sandi minimal 6 karakter'));
    }

    // --- Autentikasi via repository (kontrak domain) ---
    final auth = await _repository.login(email: normalizedEmail, password: password);
    if (auth.failure != null) return failure(auth.failure!);

    // --- Persistensi sesi via store (kontrak domain) ---
    try {
      await _store.save(access: auth.value!.access, refresh: auth.value!.refresh);
    } catch (e) {
      return failure(LocalFailure('Gagal menyimpan sesi: $e'));
    }
    return success(auth.value!);
  }
}
