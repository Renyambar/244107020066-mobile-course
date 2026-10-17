import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'data/models/post.dart';
import 'pages/paged_post_page.dart';
import 'pages/post_detail_page.dart';
import 'pages/post_list_page.dart';

/// Konfigurasi rute terpusat (Refactoring Challenge #3):
/// - `/`         : halaman paginated (infinite scroll) — halaman utama.
/// - `/all`      : halaman daftar penuh 100 post (empat state AsyncValue).
/// - `/post/:id` : halaman detail post + komentar.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const PagedPostPage(),
      ),
      GoRoute(
        path: '/all',
        builder: (context, state) => const PostListPage(),
      ),
      GoRoute(
        path: '/post/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final extra = state.extra;
          return PostDetailPage(
            postId: id,
            initialPost: extra is Post ? extra : null,
          );
        },
      ),
    ],
  );
});

void main() => runApp(const ProviderScope(child: MyApp()));

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Week 4 - REST API',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
