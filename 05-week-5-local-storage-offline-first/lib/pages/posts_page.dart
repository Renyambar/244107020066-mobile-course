import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../widgets/format.dart';
import '../widgets/offline_banner.dart';

/// Offline-first #1 — **cache-first read** untuk data API
/// (`GET /posts`, endpoint yang sama dengan Minggu 4).
///
/// Alurnya: tampilkan cache lokal seketika → refresh dari jaringan di
/// background → simpan ke tabel `cached_posts` untuk kunjungan berikutnya.
class PostsPage extends ConsumerWidget {
  const PostsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final postsAsync = ref.watch(postsCacheProvider);
    final offline = ref.watch(forceOfflineProvider);
    final reloading = postsAsync.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Postingan — Cache First'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh (download bila online)',
            onPressed: reloading
                ? null
                : () => ref.read(postsCacheProvider.notifier).reload(),
          ),
        ],
      ),
      body: Column(
        children: [
          OfflineBanner(visible: offline),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                Chip(
                  avatar: const Icon(Icons.storage_rounded, size: 16),
                  label: Text(offline ? 'Cache lokal (offline)' : 'Cache + refresh'),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
                Chip(
                  avatar: Icon(
                    offline ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
                    size: 16,
                  ),
                  label: Text(offline ? 'Jaringan dilewat' : 'Jaringan: JSONPlaceholder'),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          Expanded(
            child: postsAsync.when(
              skipLoadingOnReload: true,
              loading: () => const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Cache kosong — mengambil dari jaringan…'),
                  ],
                ),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_rounded, size: 44),
                      const SizedBox(height: 12),
                      Text('Tidak ada data sama sekali.',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Cache kosong dan jaringan tidak tersedia.\n$error',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () =>
                            ref.read(postsCacheProvider.notifier).reload(),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (posts) {
                if (posts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_rounded,
                              size: 52, color: theme.hintColor),
                          const SizedBox(height: 12),
                          Text('Belum ada cache post',
                              style: theme.textTheme.titleLarge),
                          const SizedBox(height: 6),
                          Text(
                            'Buka halaman ini saat online sekali saja; '
                            'hasilnya disimpan di tabel cached_posts.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: theme.hintColor),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(postsCacheProvider.notifier).reload(),
                  child: ListView.separated(
                    padding: const EdgeInsets.only(top: 6, bottom: 24),
                    itemCount: posts.length + 1,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: Text(
                            '${posts.length} post dari cache lokal '
                            '(terisi ${formatRelative(posts.first.cachedAt)})',
                            style: theme.textTheme.labelMedium
                                ?.copyWith(color: theme.hintColor),
                          ),
                        );
                      }
                      final post = posts[index - 1];
                      return ListTile(
                        leading: CircleAvatar(child: Text('${post.id}')),
                        title: Text(
                          post.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          post.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: true,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
