import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stat_item.dart';
import '../providers/stats_provider.dart';

/// Halaman StatsPage yang menampilkan statistik ToDo secara asinkron
/// Menggunakan ConsumerWidget untuk mendengarkan perubahan state dari Riverpod
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. ref.watch digunakan di dalam build untuk mendengarkan perubahan state secara reaktif.
    // statsAsync bertipe AsyncValue<List<StatItem>>, yang memiliki 3 status: loading, error, dan data (success).
    final statsAsync = ref.watch(statsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik Aktivitas'),
        actions: [
          // Tombol refresh manual untuk memicu pengambilan ulang data statistik
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan Data',
            onPressed: () {
              // ref.read digunakan di dalam callback/event handler (bukan ref.watch)
              ref.read(statsProvider.notifier).refresh();
            },
          ),
        ],
      ),
      // 2. statsAsync.when menangani ketiga kemungkinan state secara komprehensif dan type-safe:
      // - loading: menampilkan indikator proses
      // - error: menampilkan pesan kesalahan dan opsi retry
      // - data: menampilkan hasil data statistik dalam ListView
      body: statsAsync.when(
        // === STATE 1: LOADING ===
        // Ditampilkan saat data sedang diambil dari server atau simulasi network delay (2 detik)
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                strokeWidth: 3,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Mengambil data statistik dari server...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '(Simulasi jeda 2 detik & potensi kegagalan 30%)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),

        // === STATE 2: ERROR ===
        // Ditampilkan saat proses pengambilan data melempar exception (simulasi kegagalan 30%)
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Card(
              elevation: 0,
              color: theme.colorScheme.errorContainer.withAlpha(80),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: theme.colorScheme.error.withAlpha(100)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: theme.colorScheme.error,
                      size: 54,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal Memuat Statistik',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString().replaceAll('Exception: ', ''),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Tombol 'Coba Lagi' menggunakan ref.invalidate untuk memicu ulang build() provider
                    FilledButton.icon(
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('Coba Lagi'),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                      ),
                      onPressed: () {
                        // Membatalkan cache provider dan memicunya berjalan kembali
                        ref.invalidate(statsProvider);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // === STATE 3: SUCCESS (DATA) ===
        // Ditampilkan ketika data berhasil diambil, menampilkan 3 item statistik
          data: (List<StatItem> statsList) => ListView.separated(
          padding: const EdgeInsets.all(16.0),
          itemCount: statsList.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = statsList[index];
            final iconData = _getIconForStat(index);
            final color = _getColorForStat(index, theme);

            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(60)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withAlpha(30),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(iconData, color: color, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withAlpha(80)),
                      ),
                      child: Text(
                        item.value,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Helper untuk menentukan ikon pada setiap indeks statistik
  IconData _getIconForStat(int index) {
    switch (index) {
      case 0:
        return Icons.format_list_bulleted_rounded;
      case 1:
        return Icons.task_alt_rounded;
      case 2:
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  /// Helper untuk menentukan aksen warna pada setiap indeks statistik
  Color _getColorForStat(int index, ThemeData theme) {
    switch (index) {
      case 0:
        return theme.colorScheme.primary;
      case 1:
        return Colors.green.shade700;
      case 2:
      default:
        return Colors.amber.shade800;
    }
  }
}
