import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/models/post.dart';
import 'package:week4_api/data/paged_posts.dart';
import 'package:week4_api/data/providers.dart';
import 'package:week4_api/data/repositories/post_repository.dart';
import 'package:week4_api/pages/paged_post_page.dart';
import 'package:week4_api/widgets/post_tile.dart';

/// Fake repository untuk widget test — menggantikan request jaringan nyata.
class FakePostRepository extends PostRepository {
  FakePostRepository({this.items = const [], this.throwError = false})
      : super(Dio());

  final List<Post> items;
  final bool throwError;

  @override
  Future<List<Post>> fetchPosts() async => items;

  @override
  Future<List<Post>> fetchPostsPage({required int page, int limit = 10}) async {
    if (throwError) {
      throw DioException(
        requestOptions: RequestOptions(path: '/posts'),
        type: DioExceptionType.connectionError,
      );
    }
    final start = (page - 1) * limit;
    if (start >= items.length) return const [];
    final end = (start + limit).clamp(0, items.length);
    return items.sublist(start, end);
  }
}

void main() {
  testWidgets('PostTile menampilkan id, judul, dan isi post', (tester) async {
    const post = Post(userId: 1, id: 42, title: 'Judul Tile', body: 'Isi tile');

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PostTile(post: post))),
    );

    expect(find.text('42'), findsOneWidget);
    expect(find.text('Judul Tile'), findsOneWidget);
    expect(find.text('Isi tile'), findsOneWidget);
  });

  testWidgets('PagedPostPage menampilkan data dari repository palsu',
      (tester) async {
    final posts = List.generate(
      10,
      (i) => Post(userId: 1, id: i + 1, title: 'Post ${i + 1}', body: 'Isi'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          postRepositoryProvider
              .overrideWithValue(FakePostRepository(items: posts)),
        ],
        child: const MaterialApp(home: PagedPostPage()),
      ),
    );

    // Halaman pertama dimuat lewat Future.microtask. pumpAndSettle tidak
    // dipakai karena footer CircularProgressIndicator (halaman berikutnya
    // masih tersedia) terus beranimasi dan tidak pernah "settle".
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Post 1'), findsOneWidget);
    expect(find.text('Post 10'), findsOneWidget);
  });

  testWidgets('PagedPostPage menampilkan pesan error + tombol retry',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          postRepositoryProvider.overrideWithValue(
            FakePostRepository(throwError: true),
          ),
        ],
        child: const MaterialApp(home: PagedPostPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tidak dapat terhubung ke server. Periksa internet Anda.'),
        findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });

  test('PagedPostsState default: masih loading lebih & punya data', () {
    const state = PagedPostsState();
    expect(state.items, isEmpty);
    expect(state.page, 0);
    expect(state.isLoadingMore, isFalse);
    expect(state.hasMore, isTrue);
    expect(state.error, isNull);
  });
}
