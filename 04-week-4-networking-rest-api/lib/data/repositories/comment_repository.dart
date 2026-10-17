import 'package:dio/dio.dart';

import '../models/comment.dart';

/// Hasil AI Prompt Challenge — repository untuk endpoint
/// `GET /comments?postId={id}` dari JSONPlaceholder.
///
/// Memakai Dio yang sama (timeout 10 detik dari `createDio()`), sehingga
/// konfigurasi jaringan tetap terpusat di `api_client.dart`.
class CommentRepository {
  CommentRepository(this._dio);

  final Dio _dio;

  Future<List<Comment>> fetchComments(int postId) async {
    final response = await _dio.get<List<dynamic>>(
      '/comments',
      queryParameters: {'postId': postId},
    );
    final data = response.data ?? const <dynamic>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(Comment.fromJson)
        .toList();
  }
}
