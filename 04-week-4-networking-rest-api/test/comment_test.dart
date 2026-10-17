import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/models/comment.dart';
import 'package:week4_api/data/network_errors.dart';
import 'package:week4_api/data/providers.dart';
import 'package:week4_api/data/repositories/comment_repository.dart';

/// Fake CommentRepository: mengembalikan komentar tanpa HTTP sungguhan,
/// atau melempar DioException untuk menguji pemetaan error.
class FakeCommentRepository extends CommentRepository {
  FakeCommentRepository({this.items, this.statusCode})
      : super(Dio());

  final List<Comment>? items;
  final int? statusCode;

  @override
  Future<List<Comment>> fetchComments(int postId) async {
    if (statusCode != null) {
      throw DioException(
        requestOptions: RequestOptions(path: '/comments'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/comments'),
          statusCode: statusCode,
        ),
      );
    }
    return items ?? const [];
  }
}

/// Membaca state pertama yang bukan loading dari provider keluarga komentar.
Future<Object?> readCommentsErrorOnce(
  ProviderContainer container,
  int postId,
) {
  final completer = Completer<Object?>();
  final sub = container.listen<AsyncValue<List<Comment>>>(
    commentsProvider(postId),
    (previous, next) {
      if (next.isLoading || completer.isCompleted) return;
      completer.complete(next.error ?? next.value);
    },
    fireImmediately: true,
  );
  return completer.future.whenComplete(sub.close);
}

void main() {
  test('Comment.fromJson aman terhadap field yang hilang', () {
    // Kasus edge case: server hanya mengirim id, field lain hilang semua.
    final comment = Comment.fromJson({'id': 3});
    expect(comment.id, 3);
    expect(comment.postId, 0);
    expect(comment.name, '');
    expect(comment.email, '');
    expect(comment.body, '');
  });

  test('Comment.fromJson aman terhadap field bertipe salah', () {
    final comment = Comment.fromJson({
      'postId': '2', // server mengirim String, bukan num
      'id': 9,
      'name': null,
    });
    expect(comment.postId, 2);
    expect(comment.id, 9);
    expect(comment.name, '');
  });

  test('friendlyErrorMessage memetakan 404 ke pesan ramah', () {
    final err = DioException(
      requestOptions: RequestOptions(path: '/posts/999'),
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: RequestOptions(path: '/posts/999'),
        statusCode: 404,
      ),
    );
    expect(friendlyErrorMessage(err), contains('404'));
  });

  test('friendlyErrorMessage memetakan timeout ke pesan ramah', () {
    final err = DioException(
      requestOptions: RequestOptions(path: '/posts'),
      type: DioExceptionType.receiveTimeout,
    );
    expect(friendlyErrorMessage(err), contains('timeout'));
  });

  test('provider komentar error dengan repository palsu', () async {
    final container = ProviderContainer(
      overrides: [
        commentRepositoryProvider.overrideWithValue(
          FakeCommentRepository(statusCode: 404),
        ),
      ],
    );
    addTearDown(container.dispose);

    final err = await readCommentsErrorOnce(container, 1);
    expect(err, isA<DioException>());
    expect(friendlyErrorMessage(err!), contains('404'));
  });
}
