import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/todo.dart';
import '../providers/todo_provider.dart';

/// Widget TodoTile yang telah dipisahkan agar build method lebih ringkas,
/// reusable, dan mudah diuji secara independen.
class TodoTile extends ConsumerWidget {
  final Todo todo;

  const TodoTile({
    super.key,
    required this.todo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: todo.done
              ? theme.colorScheme.outlineVariant.withAlpha(80)
              : theme.colorScheme.primary.withAlpha(40),
        ),
      ),
      color: todo.done
          ? theme.colorScheme.surfaceContainerHighest.withAlpha(120)
          : theme.colorScheme.surface,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Checkbox(
          value: todo.done,
          activeColor: theme.colorScheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          onChanged: (_) {
            // Memanggil notifier untuk toggle status (immutable)
            ref.read(todoListProvider.notifier).toggle(todo.id);
          },
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            decoration: todo.done ? TextDecoration.lineThrough : null,
            color: todo.done
                ? theme.colorScheme.onSurfaceVariant.withAlpha(150)
                : theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          todo.done ? 'Status: Selesai' : 'Status: Menunggu penyelesaian',
          style: TextStyle(
            fontSize: 12,
            color: todo.done
                ? Colors.green.shade700
                : theme.colorScheme.secondary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              tooltip: 'Buka Detail',
              onPressed: () {
                // Mencontohkan navigasi GoRouter ke halaman detail dengan path parameter
                context.push('/detail/${todo.id}?title=${Uri.encodeComponent(todo.title)}&done=${todo.done}');
              },
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              tooltip: 'Hapus Tugas',
              onPressed: () {
                // Memanggil notifier untuk menghapus item
                ref.read(todoListProvider.notifier).remove(todo.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Tugas "${todo.title}" dihapus'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
