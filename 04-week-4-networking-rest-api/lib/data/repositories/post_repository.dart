import 'package:dio/dio.dart';

import '../models/post.dart';

/// Langkah 3 & 7 codelab — Repository sebagai pintu tunggal ke sumber data.
///
/// - UI tidak boleh memanggil Dio secara langsung; UI hanya membaca provider.
/// - Repository mengubah respons JSON mentah menjadi objek model Dart.
/// - Exception dibiarkan naik (tidak ditelan `catch` kosong) agar provider
///   mengubahnya menjadi `AsyncError` secara otomatis.
class PostRepository {
  PostRepository(this._dio);

  final Dio _dio;

  /// Mengambil seluruh post tanpa pagination (`GET /posts`).
  Future<List<Post>> fetchPosts() async {
    final response = await _dio.get<List<dynamic>>('/posts');
    return _parse(response.data);
  }

  /// Mengambil satu post (`GET /posts/{id}`), dipakai halaman detail.
  Future<Post> fetchPost(int id) async {
    final response = await _dio.get<Map<String, dynamic>>('/posts/$id');
    final data = response.data ?? const <String, dynamic>{};
    return Post.fromJson(data);
  }

  /// Langkah 7 — repository paginated: `GET /posts?_page=N&_limit=M`.
  ///
  /// `limit` di-return balik oleh JSONPlaceholder lewat header `x-total-count`
  /// pada kasus umum; di sini kita cukup menentukan `hasMore` berdasarkan
  /// apakah jumlah item yang diterima sama dengan `limit`.
  Future<List<Post>> fetchPostsPage({
    required int page,
    int limit = 10,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/posts',
      queryParameters: {'_page': page, '_limit': limit},
    );
    return _parse(response.data);
  }

  /// Memetakan `List<dynamic>` hasil JSON menjadi `List<Post>`, membuang
  /// elemen yang bukan `Map<String, dynamic>` (respons kotor) dan melewatkan
  /// tiap map ke `Post.fromJson` yang aman null.
  List<Post> _parse(List<dynamic>? data) {
    final list = data ?? const <dynamic>[];
    return list
        .whereType<Map<String, dynamic>>()
        .map(Post.fromJson)
        .toList();
  }
}
