import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/todo_provider.dart';
import '../widgets/todo_filter_bar.dart';
import '../widgets/todo_tile.dart';

/// Halaman utama daftar ToDo
class TodoPage extends ConsumerWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Membaca daftar ToDo hasil filter
    final filteredTodos = ref.watch(filteredTodoListProvider);
    final allTodos = ref.watch(todoListProvider);
    final theme = Theme.of(context);

    final completedCount = allTodos.where((t) => t.done).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Tugas ToDo'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              '${allTodos.length} total • $completedCount selesai • ${allTodos.length - completedCount} tertunda',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter bar menggunakan SegmentedButton
          const TodoFilterBar(),
          const SizedBox(height: 4),

          // Daftar item tugas ToDo
          Expanded(
            child: filteredTodos.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.assignment_turned_in_outlined,
                            size: 64,
                            color: theme.colorScheme.outline.withAlpha(120),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada tugas',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tambahkan tugas baru melalui tombol di bawah atau ubah opsi filter.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredTodos.length,
                    padding: const EdgeInsets.only(bottom: 80),
                    itemBuilder: (context, index) {
                      final item = filteredTodos[index];
                      return TodoTile(
                        key: ValueKey(item.id),
                        todo: item,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('Tambah Tugas'),
      ),
    );
  }

  /// Dialog untuk menambahkan tugas baru
  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tambah Tugas Baru'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Contoh: Belajar Riverpod AsyncNotifier',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            final trimmed = value.trim();
            if (trimmed.isNotEmpty) {
              ref.read(todoListProvider.notifier).add(trimmed);
              Navigator.pop(dialogContext);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final trimmed = controller.text.trim();
              if (trimmed.isNotEmpty) {
                // Menambah tugas baru lewat provider notifier
                ref.read(todoListProvider.notifier).add(trimmed);
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }
}
