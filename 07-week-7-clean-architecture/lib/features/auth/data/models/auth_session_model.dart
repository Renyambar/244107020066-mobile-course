import '../../domain/entities/auth_session.dart';

/// Representasi sesi autentikasi sebagai JSON (data luar) + pemetaan ke entity.
///
/// Pemetaan (`fromJson`/`toEntity`) hanya berada di model — domain tidak pernah
/// tahu bentuk JSON sama sekali.
class AuthSessionModel extends AuthSession {
  const AuthSessionModel({required super.access, required super.refresh});

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      access: json['access'] as String? ?? '',
      refresh: json['refresh'] as String? ?? '',
    );
  }

  /// Konversi ke entity murni pada batas data -> domain.
  AuthSession toEntity() => AuthSession(access: access, refresh: refresh);
}
