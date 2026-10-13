import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stat_item.dart';
import 'todo_provider.dart';

/// Notifier asinkron untuk mengelola data statistik ToDo
class StatsNotifier extends AsyncNotifier<List<StatItem>> {
  /// Simulator generator acak atau fungsi mock untuk kebutuhan testing
  final Random _random = Random();
  double? forcedFailureRate;

  /// Konfigurasi global simulasi jeda waktu dan kegagalan untuk kemudahan testing
  static Duration simulationDelay = const Duration(seconds: 2);
  static double? globalForcedFailureRate;

  @override
  Future<List<StatItem>> build() async {
    return _fetchStats();
  }

  /// Mengambil data statistik dengan simulasi network delay dan kemungkinan error
  Future<List<StatItem>> _fetchStats() async {
    // Simulasi latensi jaringan (dapat diset 0 saat testing)
    if (simulationDelay > Duration.zero) {
      await Future.delayed(simulationDelay);
    }

    // Cek probabilitas kegagalan (default 30% atau nilai yang dipaksakan saat test)
    final failRate = globalForcedFailureRate ?? forcedFailureRate ?? 0.3;
    if (failRate > 0 && (failRate >= 1.0 || _random.nextDouble() < failRate)) {
      throw Exception('Gagal menghubungi server statistik (Error 503: Service Unavailable).');
    }

    // Mengambil data terkini dari todoListProvider
    final todos = ref.read(todoListProvider);
    final total = todos.length;
    final completed = todos.where((t) => t.done).length;
    final pending = total - completed;

    return [
      StatItem(
        label: 'Total Tugas',
        value: '$total Tugas',
        description: 'Seluruh daftar tugas yang tersimpan pada aplikasi.',
      ),
      StatItem(
        label: 'Tugas Selesai',
        value: '$completed Tugas',
        description: 'Tugas yang telah ditandai selesai (100% tuntas).',
      ),
      StatItem(
        label: 'Tugas Tertunda',
        value: '$pending Tugas',
        description: 'Tugas yang masih memerlukan perhatian dan penyelesaian.',
      ),
    ];
  }

  /// Memperbarui data secara manual dengan memicu ulang state loading
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchStats());
  }
}

/// Provider global bertipe eksplisit AsyncNotifierProvider
final statsProvider =
    AsyncNotifierProvider<StatsNotifier, List<StatItem>>(StatsNotifier.new);
