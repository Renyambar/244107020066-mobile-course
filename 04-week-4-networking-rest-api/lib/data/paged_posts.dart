import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/post.dart';
import 'providers.dart';

/// Langkah 8 codelab — Notifier dengan state halaman (pagination).
///
/// State tersimpan dalam satu objek immutable [PagedPostsState]:
/// data lama tetap dipertahankan saat halaman berikutnya gagal dimuat,
/// sehingga UI tidak kehilangan daftar yang sedang tampil.
class PagedPostsState {
  const PagedPostsState({
    this.items = const [],
    this.page = 0,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<Post> items;
  final int page;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  PagedPostsState copyWith({
    List<Post>? items,
    int? page,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) {
    return PagedPostsState(
      items: items ?? this.items,
      page: page ?? this.page,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PagedPostsNotifier extends Notifier<PagedPostsState> {
  @override
  PagedPostsState build() {
    Future.microtask(loadFirstPage);
    return const PagedPostsState();
  }

  Future<void> loadFirstPage() async {
    final repository = ref.read(postRepositoryProvider);
    state = const PagedPostsState();
    try {
      final items = await repository.fetchPostsPage(page: 1, limit: 10);
      state = PagedPostsState(
        items: items,
        page: 1,
        hasMore: items.length == 10,
      );
    } catch (e) {
      state = PagedPostsState(error: e);
    }
  }

  Future<void> loadNextPage() async {
    // Guard penting: mencegah request ganda saat scroll listener terpanggil
    // berkali-kali, sekaligus menghentikan request saat data sudah habis.
    if (state.isLoadingMore || !state.hasMore) return;
    final repo = ref.read(postRepositoryProvider);
    final currentItems = state.items;
    final currentPage = state.page;
    state = PagedPostsState(
      items: currentItems,
      page: currentPage,
      isLoadingMore: true,
      hasMore: state.hasMore,
    );
    try {
      final next = currentPage + 1;
      final items = await repo.fetchPostsPage(page: next, limit: 10);
      state = PagedPostsState(
        items: [...currentItems, ...items],
        page: next,
        hasMore: items.length == 10,
      );
    } catch (e) {
      // Data lama dipertahankan, hanya error yang dicatat.
      state = PagedPostsState(
        items: currentItems,
        page: currentPage,
        error: e,
      );
    }
  }
}

final pagedPostsProvider =
    NotifierProvider<PagedPostsNotifier, PagedPostsState>(
      PagedPostsNotifier.new,
    );
