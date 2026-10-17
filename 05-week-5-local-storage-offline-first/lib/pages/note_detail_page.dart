import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/local/note.dart';
import '../data/providers.dart';
import '../data/sync.dart';
import '../widgets/format.dart';

/// Refactoring #3 — halaman detail `/note/:id` dengan GoRouter.
///
/// Membaca catatan **dari repository lokal** (`noteDetailProvider`) berdasarkan
/// id pada URL, bukan dari state halaman list, sehingga deep-link / refresh
/// pun tetap menampilkan data yang benar.
class NoteDetailPage extends ConsumerWidget {
  const NoteDetailPage({super.key, required this.id});

  final int id;

  Future<void> _edit(BuildContext context, WidgetRef ref, Note note) async {
    final titleController = TextEditingController(text: note.title);
    final bodyController = TextEditingController(text: note.body);

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Edit catatan #${note.id}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Judul'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyController,
                minLines: 4,
                maxLines: 8,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Isi catatan',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const Text('Simpan'),
          ),
        ],
      ),
    );

    final title = titleController.text.trim();
    final body = bodyController.text.trim();
    titleController.dispose();
    bodyController.dispose();

    if (saved != true || title.isEmpty) return;
    await ref
        .read(notesProvider.notifier)
        .updateNote(id, title: title, body: body);
    ref.invalidate(noteDetailProvider(id));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catatan diperbarui — dirty = 1, menunggu sinkronisasi'),
        ),
      );
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus catatan?'),
        content: Text('"${note.title}" akan dihapus dari SQLite.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(notesProvider.notifier).deleteNote(note.id!);
    ref.invalidate(noteDetailProvider(id));
    if (context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(noteDetailProvider(id));

    return Scaffold(
      appBar: AppBar(title: Text('Catatan #$id')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Gagal membaca catatan: $error',
                textAlign: TextAlign.center),
          ),
        ),
        data: (note) {
          if (note == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search_off_rounded, size: 48),
                  const SizedBox(height: 12),
                  Text('Catatan #$id tidak ditemukan.',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.pop(),
                    child: const Text('Kembali'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Badge(
                    backgroundColor: note.dirty
                        ? theme.colorScheme.errorContainer
                        : theme.colorScheme.primaryContainer,
                    textColor: note.dirty
                        ? theme.colorScheme.onErrorContainer
                        : theme.colorScheme.onPrimaryContainer,
                    label: Text(note.syncLabel),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: Icon(
                      note.dirty
                          ? Icons.cloud_off_outlined
                          : Icons.cloud_done_outlined,
                      size: 16,
                    ),
                    label: Text(note.dirty
                        ? 'Antrean sinkron'
                        : 'Sudah tersinkron'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(note.title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                'id: ${note.id}  •  updated_at: ${formatDateTime(note.updatedAt)}',
                style: theme.textTheme.labelMedium?.copyWith(color: theme.hintColor),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    note.body.isEmpty ? '(catatan tanpa isi)' : note.body,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _edit(context, ref, note),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _delete(context, ref, note),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Hapus'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sumber data & aturan konflik',
                          style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Text(
                        'Dibaca lewat NoteRepository (SQLite lokal) dengan id '
                        'dari URL /note/:id — bukan state halaman daftar.\n'
                        'Aturan konflik: $conflictRule. Setiap edit memperbarui '
                        'updated_at dan menandai dirty = 1.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
