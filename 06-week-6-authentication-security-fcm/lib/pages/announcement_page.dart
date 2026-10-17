import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../routes.dart';

/// Data pengumuman contoh (sumber statis, backend sebenarnya lewat API).
class Announcement {
  const Announcement({required this.id, required this.title, required this.body});
  final String id;
  final String title;
  final String body;
}

const List<Announcement> kAnnouncements = [
  Announcement(
    id: '1',
    title: 'Kuliah Pengganti Minggu Ini',
    body: 'Kelas Mobile Development dipindah ke Ruang A2, Rabu 13.00 WIB.',
  ),
  Announcement(
    id: '2',
    title: 'Uts Praktikum',
    body: 'UTS praktikum dilaksanakan di lab komputer Lt.3, bawa laptop sendiri.',
  ),
  Announcement(
    id: '3',
    title: 'Jadwal Kuliah Berubah',
    body: 'Kelas Mobile pindah ke Ruang A2 jam 13.00.',
  ),
];

/// Halaman detail pengumuman — tujuan deep link dari notifikasi.
class AnnouncementPage extends ConsumerWidget {
  const AnnouncementPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcement = kAnnouncements
        .where((a) => a.id == id)
        .cast<Announcement?>()
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(title: Text('Pengumuman #$id')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: announcement == null
            ? const Center(child: Text('Pengumuman tidak ditemukan'))
            : Column(
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
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
