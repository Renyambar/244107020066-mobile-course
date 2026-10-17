/// Sesi autentikasi hasil login (domain murni Dart, tanpa mapping JSON).
///
/// Objek bisnis murni: tidak punya `toMap`/`fromMap`/`toJson`. Pemetaan
/// ke/dari JSON & secure storage hidup di lapisan `data`.
class AuthSession {
  const AuthSession({required this.access, required this.refresh});

  final String access;
  final String refresh;
}

/// Profil singkat dari `GET /me` (domain murni).
class CampusProfile {
  const CampusProfile({
    required this.name,
    required this.nim,
    required this.kelas,
  });

  final String name;
  final String nim;
  final String kelas;
}
