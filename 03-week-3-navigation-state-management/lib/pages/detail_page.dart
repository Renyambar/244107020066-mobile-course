import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/todo_provider.dart';

/// Halaman Detail yang mendemonstrasikan router deklaratif GoRouter
/// Menerima parameter path `:id` dan query parameter tambahan
class DetailPage extends ConsumerWidget {
  final String id;
  final String? initialTitle;
  final bool? initialDone;

  const DetailPage({
    super.key,
    required this.id,
    this.initialTitle,
    this.initialDone,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mencari objek ToDo langsung dari provider berdasarkan ID
    final todos = ref.watch(todoListProvider);
    final todoItem = todos.cast<dynamic>().firstWhere(
          (t) => t.id == id,
          orElse: () => null,
        );

    final displayTitle = todoItem?.title ?? initialTitle ?? 'Item ID: $id';
    final isDone = todoItem?.done ?? initialDone ?? false;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Tugas #$id'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Kembali ke halaman sebelumnya dalam stack navigasi
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: isDone
                          ? Colors.green.shade100
                          : theme.colorScheme.primaryContainer,
                      child: Icon(
                        isDone ? Icons.check_circle_rounded : Icons.pending_rounded,
                        size: 40,
                        color: isDone
                            ? Colors.green.shade800
                            : theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      displayTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      backgroundColor: isDone
                          ? Colors.green.shade50
                          : theme.colorScheme.surfaceContainerHighest,
                      label: Text(
                        isDone ? 'Tuntas Selesai' : 'Belum Selesai',
                        style: TextStyle(
                          color: isDone ? Colors.green.shade900 : theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(height: 36),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('ID Unik Rute:', style: theme.textTheme.bodyMedium),
                        Text(
                          id,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Mekanisme Rute:', style: theme.textTheme.bodyMedium),
                        const Text(
                          'GoRouter Path Parameter',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (todoItem != null)
              FilledButton.icon(
                icon: Icon(isDone ? Icons.undo : Icons.check),
                label: Text(isDone ? 'Tandai Belum Selesai' : 'Tandai Selesai'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  ref.read(todoListProvider.notifier).toggle(id);
                },
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.arrow_back),
              label: const Text('Kembali ke Daftar Tugas'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
