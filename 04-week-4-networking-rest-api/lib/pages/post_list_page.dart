import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/network_errors.dart';
import '../data/providers.dart';
import '../widgets/post_tile.dart';

/// Langkah 5 codelab — UI dengan empat state: loading, error, empty, success.
///
/// Widget ini tidak memanggil Dio langsung; ia hanya `ref.watch`
/// [postListProvider] lalu merender `postsAsync.when(...)`.
class PostListPage extends ConsumerWidget {
  const PostListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts API'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(postListProvider.notifier).refresh(),
          ),
        ],
      ),
      body: postsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off,
                    size: 48, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 12),
                Text(friendlyErrorMessage(err), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(postListProvider),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(child: Text('Belum ada data dari server.'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(postListProvider.notifier).refresh(),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return PostTile(
                  post: post,
                  onTap: () => context.push('/post/${post.id}', extra: post),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
