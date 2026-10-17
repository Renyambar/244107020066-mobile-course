import '../../domain/entities/auth_session.dart';

/// Representasi profil `GET /me` sebagai JSON + pemetaan ke entity.
class CampusProfileModel extends CampusProfile {
  const CampusProfileModel({
    required super.name,
    required super.nim,
    required super.kelas,
  });

  factory CampusProfileModel.fromJson(Map<String, dynamic> json) {
    return CampusProfileModel(
      name: json['name'] as String? ?? '-',
      nim: json['nim'] as String? ?? '-',
      kelas: json['kelas'] as String? ?? '-',
    );
  }

  CampusProfile toEntity() =>
      CampusProfile(name: name, nim: nim, kelas: kelas);
}
