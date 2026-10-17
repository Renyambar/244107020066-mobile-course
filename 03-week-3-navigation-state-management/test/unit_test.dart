import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week03/models/stat_item.dart';
import 'package:week03/providers/stats_provider.dart';
import 'package:week03/providers/todo_provider.dart';

void main() {
  group('TodoListNotifier Unit Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('State awal memiliki 3 item default', () {
      final todos = container.read(todoListProvider);
      expect(todos.length, 3);
      expect(todos[0].done, isTrue);
      expect(todos[1].done, isFalse);
    });

    test('add() menambah tugas baru secara immutable', () {
      final notifier = container.read(todoListProvider.notifier);
      notifier.add('Tugas Baru Unit Test');

      final todos = container.read(todoListProvider);
      expect(todos.length, 4);
      expect(todos.last.title, 'Tugas Baru Unit Test');
      expect(todos.last.done, isFalse);
    });

    test('toggle() mengubah status tugas', () {
      final notifier = container.read(todoListProvider.notifier);
      final initialTodo = container.read(todoListProvider).first;
      expect(initialTodo.done, isTrue);

      notifier.toggle(initialTodo.id);
      final updatedTodo = container.read(todoListProvider).first;
      expect(updatedTodo.done, isFalse);
    });

    test('remove() menghapus tugas berdasarkan ID', () {
      final notifier = container.read(todoListProvider.notifier);
      final initialCount = container.read(todoListProvider).length;

      notifier.remove('1');
      final todos = container.read(todoListProvider);
      expect(todos.length, initialCount - 1);
      expect(todos.any((t) => t.id == '1'), isFalse);
    });

    test('filteredTodoListProvider menyaring berdasarkan TodoFilter', () {
      final filterNotifier = container.read(todoFilterProvider.notifier);

      // Default (All)
      expect(container.read(filteredTodoListProvider).length, 3);

      // Filter: Active
      filterNotifier.setFilter(TodoFilter.active);
      final activeTodos = container.read(filteredTodoListProvider);
      expect(activeTodos.every((t) => !t.done), isTrue);
      expect(activeTodos.length, 2);

      // Filter: Completed
      filterNotifier.setFilter(TodoFilter.completed);
      final completedTodos = container.read(filteredTodoListProvider);
      expect(completedTodos.every((t) => t.done), isTrue);
      expect(completedTodos.length, 1);
    });
  });

  group('StatsNotifier Unit Tests', () {
    setUp(() {
      StatsNotifier.simulationDelay = Duration.zero;
    });

    tearDown(() {
      StatsNotifier.globalForcedFailureRate = null;
      StatsNotifier.simulationDelay = const Duration(seconds: 2);
    });

    test('Berhasil memuat data statistik (AsyncData) dengan 3 item', () async {
      StatsNotifier.globalForcedFailureRate = 0.0;
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Membaca statsProvider dan menunggu hasil build Future-nya selesai
      final statsFuture = container.read(statsProvider.future);
      final stats = await statsFuture;

      expect(stats, isA<List<StatItem>>());
      expect(stats.length, 3);
      expect(stats[0].label, 'Total Tugas');
      expect(stats[1].label, 'Tugas Selesai');
      expect(stats[2].label, 'Tugas Tertunda');

      final state = container.read(statsProvider);
      expect(state, isA<AsyncData<List<StatItem>>>());
    });

    test('Menangani kesalahan (AsyncError) saat simulasi request gagal', () async {
      StatsNotifier.globalForcedFailureRate = 1.0; // Paksa gagal 100%
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Menambahkan listener untuk menjaga siklus hidup provider
      final sub = container.listen<AsyncValue<List<StatItem>>>(
        statsProvider,
        (previous, next) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);

      // Tunggu hingga build() selesai dieksekusi
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(statsProvider);
      expect(state.hasError, isTrue);
      expect(state.error.toString(), contains('Gagal menghubungi server statistik'));

      // Pengujian refresh() menggunakan AsyncValue.guard menghasilkan AsyncError
      await container.read(statsProvider.notifier).refresh();
      final refreshedState = container.read(statsProvider);
      expect(refreshedState, isA<AsyncError<List<StatItem>>>());
      expect(refreshedState.hasError, isTrue);
    });

    test('refresh() memicu ulang pemanggilan data statistik', () async {
      StatsNotifier.globalForcedFailureRate = 0.0;
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(statsProvider.future);
      expect(container.read(statsProvider), isA<AsyncData<List<StatItem>>>());

      await container.read(statsProvider.notifier).refresh();
      expect(container.read(statsProvider), isA<AsyncData<List<StatItem>>>());
    });
  });
}
