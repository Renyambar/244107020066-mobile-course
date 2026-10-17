import '../../../../core/failures.dart';
import '../entities/auth_session.dart';

/// Kontrak autentikasi yang dibutuhkan domain (interface di `domain`).
///
/// Kontrak hanya menyebut *apa* yang bisa dilakukan (autentikasi & membaca
/// profil), bukan *bagaimana* (mock backend, Firebase Auth, Dio, dsb.).
/// Implementasi berada di `data/auth_repository_impl.dart`.
abstract class AuthRepository {
  /// Autentikasi [email]/[password]. **Tidak** menyimpan sesi — penyimpanan
  /// adalah tanggung jawab use case [Login] lewat [SessionStore].
  Future<Result<AuthSession>> login({
    required String email,
    required String password,
  });

  /// Ambil profil `GET /me`. Interceptor 401 -> refresh -> retry bekerja di
  /// balik layar pada lapisan data; presentation hanya melihat [CampusProfile].
  Future<Result<CampusProfile>> fetchProfile();
}
