import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/network_errors.dart';
import '../data/paged_posts.dart';
import '../widgets/post_tile.dart';

/// Langkah 9 codelab — UI infinite scroll.
///
/// ScrollController memicu `loadNextPage()` 200px sebelum ujung list.
/// Item footer menampilkan indikator loading saat halaman berikutnya diambil,
/// atau teks "Semua data termuat." ketika `hasMore == false`.
class PagedPostPage extends ConsumerStatefulWidget {
  const PagedPostPage({super.key});

  @override
  ConsumerState<PagedPostPage> createState() => _PagedPostPageState();
}

class _PagedPostPageState extends ConsumerState<PagedPostPage> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    if (_controller.position.extentAfter < 200) {
      ref.read(pagedPostsProvider.notifier).loadNextPage();
    }
  }

  /// Memuat halaman berikutnya bila daftar belum memenuhi layar.
  ///
  /// Diperlukan karena pada layar tinggi (390x844) 10 item pertama masih muat
  /// semua sehingga `maxScrollExtent == 0` dan scroll listener tidak pernah
  /// terpicu — indikator loading di footer akan berputar tanpa pernah memuat
  /// data berikutnya. Guard `isLoadingMore`/`hasMore` tetap menjamin tidak ada
  /// request ganda.
  void _loadIfViewportNotFull() {
    if (!mounted || !_controller.hasClients) return;
    final state = ref.read(pagedPostsProvider);
    if (!state.hasMore || state.isLoadingMore) return;
    if (_controller.position.extentAfter < 200) {
      ref.read(pagedPostsProvider.notifier).loadNextPage();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pagedPostsProvider);

    // Setelah frame dirender, pastikan daftar masih menyisakan ruang di bawah;
    // bila ya, halaman berikutnya dimuat otomatis (lihat _loadIfViewportNotFull).
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadIfViewportNotFull());

    // State error dengan data kosong: tampilkan layar penuh + tombol retry.
    if (state.error != null && state.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Posts Paged')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off,
                    size: 48, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 12),
                Text(
                  friendlyErrorMessage(state.error!),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () =>
                      ref.read(pagedPostsProvider.notifier).loadFirstPage(),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts Paged'),
        actions: [
          IconButton(
            tooltip: 'Semua post',
            icon: const Icon(Icons.list_alt),
            onPressed: () => context.go('/all'),
          ),
          IconButton(
            tooltip: 'Muat ulang halaman pertama',
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(pagedPostsProvider.notifier).loadFirstPage(),
          ),
        ],
      ),
      body: NotificationListener<ScrollNotification>(
        // Selain ScrollController, metrik scroll dipantau lewat notifikasi
        // agar halaman berikutnya juga termuat otomatis ketika daftar belum
        // memenuhi layar (maxScrollExtent == 0 sehingga scroll listener
        // tidak pernah terpicu pada layar tinggi).
        onNotification: (notification) {
          if (notification.metrics.extentAfter < 200) {
            ref.read(pagedPostsProvider.notifier).loadNextPage();
          }
          return false;
        },
        child: ListView.builder(
          controller: _controller,
          itemCount: state.items.length + 1,
          itemBuilder: (context, index) {
            if (index == state.items.length) {
              if (!state.hasMore) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: Text('Semua data termuat.')),
                );
              }
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final post = state.items[index];
            return PostTile(
              post: post,
              showBody: false,
              onTap: () => context.push('/post/${post.id}', extra: post),
            );
          },
        ),
      ),
    );
  }
}
