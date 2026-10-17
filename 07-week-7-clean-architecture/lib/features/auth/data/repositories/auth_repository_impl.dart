import 'package:dio/dio.dart';

import '../../../../core/failures.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/session_store.dart';
import '../models/auth_session_model.dart';
import '../models/campus_profile_model.dart';
import '../sources/campus_api_client.dart';
import '../sources/demo_campus_server.dart';
import '../sources/mock_auth_api.dart';

/// Implementasi [AuthRepository] di lapisan `data`.
///
/// - Autentikasi via [MockAuthApi] (mock backend).
/// - `fetchProfile` memakai [Dio] + interceptor refresh 401 -> retry, dengan
///   adapter [DemoCampusServer] sebagai server tiruan (lihat dokumentasinya).
/// - Semua exception dipetakan menjadi [Failure] — presentation tak pernah
///   melihat `DioException` ataupun `AuthApiException`.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required MockAuthApi api, required SessionStore store})
      : _api = api {
    _client = buildCampusApiClient(store: store, refresh: api.refresh)
      // Codelab tanpa backend sungguhan: pasang server tiruan yang memicu 401
      // sekali agar interceptor produksi teruji nyata.
      ..httpClientAdapter = DemoCampusServer();
  }

  final MockAuthApi _api;
  late final Dio _client;

  @override
  Future<Result<AuthSession>> login({
    required String email,
    required String password,
  }) async {
    try {
      final raw = await _api.login(email: email, password: password);
      // Pemetaan JSON -> entity terjadi di model, bukan di domain.
      return success(AuthSessionModel.fromJson(raw).toEntity());
    } on AuthApiException catch (e) {
      return failure(AuthFailure(e.message));
    } catch (e) {
      return failure(NetworkFailure('Gagal menghubungi layanan masuk: $e'));
    }
  }

  @override
  Future<Result<CampusProfile>> fetchProfile() async {
    try {
      final res = await _client.get<Map<String, dynamic>>('/me');
      final data = res.data ?? <String, dynamic>{};
      return success(CampusProfileModel.fromJson(data).toEntity());
    } on DioException catch (e) {
      return failure(NetworkFailure(apiErrorMessage(e)));
    } catch (e) {
      return failure(NetworkFailure('Gagal membaca profil: $e'));
    }
  }
}
