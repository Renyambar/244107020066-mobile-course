import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/todo_provider.dart';

/// Widget bilah filter untuk memilih kategori ToDo yang ditampilkan
class TodoFilterBar extends ConsumerWidget {
  const TodoFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(todoFilterProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SegmentedButton<TodoFilter>(
        segments: const [
          ButtonSegment<TodoFilter>(
            value: TodoFilter.all,
            label: Text('Semua'),
            icon: Icon(Icons.list_alt_rounded),
          ),
          ButtonSegment<TodoFilter>(
            value: TodoFilter.active,
            label: Text('Aktif'),
            icon: Icon(Icons.pending_actions_rounded),
          ),
          ButtonSegment<TodoFilter>(
            value: TodoFilter.completed,
            label: Text('Selesai'),
            icon: Icon(Icons.task_alt_rounded),
          ),
        ],
        selected: {currentFilter},
        onSelectionChanged: (newSelection) {
          ref.read(todoFilterProvider.notifier).setFilter(newSelection.first);
        },
      ),
    );
  }
}
