import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/failures.dart';
import '../../../../routes.dart';
import '../providers/announcements_providers.dart';

/// Halaman detail pengumuman — tujuan deep link dari notifikasi.
///
/// Halaman steril: hanya membaca `announcementDetailProvider`; tidak ada
/// parsing JSON, HTTP, maupun akses sumber data langsung.
class AnnouncementPage extends ConsumerWidget {
  const AnnouncementPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(announcementDetailProvider(id));

    return Scaffold(
      appBar: AppBar(title: Text('Pengumuman #$id')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text(
              error is Failure ? error.message : 'Terjadi kesalahan.',
              textAlign: TextAlign.center,
            ),
          ),
          data: (announcement) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Chip(
                avatar: const Icon(Icons.notifications_active, size: 18),
                label: Text('Deep link /pengumuman/$id'),
              ),
              const SizedBox(height: 16),
              Text(
                announcement.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                announcement.body,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('Kembali ke beranda'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
