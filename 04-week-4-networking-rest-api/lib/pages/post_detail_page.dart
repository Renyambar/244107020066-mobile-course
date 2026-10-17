import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/comment.dart';
import '../data/models/post.dart';
import '../data/network_errors.dart';
import '../data/providers.dart';

/// Refactoring Challenge #3 + AI Prompt Challenge — halaman detail post.
///
/// - `initialPost` diisi lewat `extra` GoRouter saat halaman dibuka dari
///   daftar, sehingga judul/isi langsung tampil tanpa request ulang.
/// - Bila dibuka langsung (deep link), post diambil ulang dari repository
///   lewat `postDetailProvider`.
/// - Daftar komentar diambil dari `GET /comments?postId={id}` lewat
///   `commentsProvider` (AsyncError otomatis dari Riverpod).
class PostDetailPage extends ConsumerWidget {
  const PostDetailPage({super.key, required this.postId, this.initialPost});

  final int postId;
  final Post? initialPost;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Post? initial = initialPost;
    final detailAsync = initial != null
        ? AsyncData(initial)
        : ref.watch(postDetailProvider(postId));

    return Scaffold(
      appBar: AppBar(title: Text('Post #$postId')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(friendlyErrorMessage(err), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(postDetailProvider(postId)),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
        data: (post) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(post.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Oleh pengguna #${post.userId}',
                style: Theme.of(context).textTheme.labelMedium),
            const Divider(height: 32),
            Text(post.body, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            Text('Komentar', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _CommentList(postId: postId),
          ],
        ),
      ),
    );
  }
}

class _CommentList extends ConsumerWidget {
  const _CommentList({required this.postId});

  final int postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentsAsync = ref.watch(commentsProvider(postId));

    return commentsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Komentar gagal dimuat. ${friendlyErrorMessage(err)}',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
      data: (comments) {
        if (comments.isEmpty) {
          return const Text('Belum ada komentar.');
        }
        return Column(
          children: [
            for (final comment in comments) _CommentTile(comment: comment),
          ],
        );
      },
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final Comment comment;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(comment.name,
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: scheme.primary)),
            Text(comment.email,
                style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 6),
            Text(comment.body),
          ],
        ),
      ),
    );
  }
}
