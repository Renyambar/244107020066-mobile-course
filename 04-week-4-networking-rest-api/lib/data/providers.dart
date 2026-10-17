import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'models/comment.dart';
import 'models/post.dart';
import 'repositories/comment_repository.dart';
import 'repositories/post_repository.dart';

/// Langkah 4 — Provider: jembatan antara repository dan UI.
///
/// UI hanya `ref.watch` provider dan membaca `AsyncValue`
/// (loading / error / data), tanpa pernah menyentuh Dio.

final dioProvider = Provider<Dio>((ref) => createDio());

final postRepositoryProvider = Provider<PostRepository>(
  (ref) => PostRepository(ref.watch(dioProvider)),
);

final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => CommentRepository(ref.watch(dioProvider)),
);

class PostListNotifier extends AsyncNotifier<List<Post>> {
  @override
  Future<List<Post>> build() async {
    // Exception dari repository otomatis menjadi AsyncError.
    // Inilah ekuivalen deklaratif dari AsyncValue.guard di versi lama.
    final repository = ref.watch(postRepositoryProvider);
    return repository.fetchPosts();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(postRepositoryProvider);
      state = AsyncData(await repository.fetchPosts());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final postListProvider = AsyncNotifierProvider<PostListNotifier, List<Post>>(
  PostListNotifier.new,
  // Nonaktifkan retry otomatis Riverpod 3 agar error langsung final dan
  // mudah diuji (tanpa ini, provider yang diuji akan me-retry dan menggantung).
  retry: (retryCount, error) => null,
);

/// Halaman detail post: diambil lewat repository (`GET /posts/{id}`).
final postDetailProvider = FutureProvider.autoDispose.family<Post, int>((
  ref,
  id,
) {
  return ref.watch(postRepositoryProvider).fetchPost(id);
});

/// Hasil AI Prompt Challenge — AsyncNotifierProvider komentar per post.
///
/// Error dari `fetchComments` otomatis menjadi `AsyncError`, sehingga UI
/// cukup membaca `AsyncValue` tanpa try/catch di widget.
class CommentListNotifier extends AsyncNotifier<List<Comment>> {
  CommentListNotifier(this.postId);

  final int postId;

  @override
  Future<List<Comment>> build() {
    final repository = ref.watch(commentRepositoryProvider);
    return repository.fetchComments(postId);
  }
}

final commentsProvider =
    AsyncNotifierProvider.family<CommentListNotifier, List<Comment>, int>(
      CommentListNotifier.new,
      retry: (retryCount, error) => null,
    );

// ---------------------------------------------------------------------------
// Helper khusus testing: membaca state pertama yang bukan loading lewat
// listener + completer, sehingga test tidak menunggu retry dan tidak
// melakukan HTTP sungguhan.
// ---------------------------------------------------------------------------

Future<List<Post>> readPostsOnce(ProviderContainer container) {
  final completer = Completer<List<Post>>();
  final sub = container.listen<AsyncValue<List<Post>>>(
    postListProvider,
    (previous, next) {
      if (next.isLoading || completer.isCompleted) return;
      next.whenData(completer.complete);
      if (next.hasError) {
        completer.completeError(
          next.error ?? StateError('unknown error'),
          next.stackTrace ?? StackTrace.empty,
        );
      }
    },
    fireImmediately: true,
  );
  return completer.future.whenComplete(sub.close);
}

Future<Object?> readPostsErrorOnce(ProviderContainer container) {
  final completer = Completer<Object?>();
  final sub = container.listen<AsyncValue<List<Post>>>(
    postListProvider,
    (previous, next) {
      if (next.isLoading || completer.isCompleted) return;
      completer.complete(next.error);
    },
    fireImmediately: true,
  );
  return completer.future.whenComplete(sub.close);
}
