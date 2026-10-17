import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/providers.dart';
import '../widgets/note_tile.dart';
import '../widgets/offline_banner.dart';
import '../widgets/sync_queue_bar.dart';

/// Langkah 4 (Halaman catatan offline) — codelab Minggu 5.
///
/// Semua data dibaca lewat `notesProvider` (AsyncValue), tidak pernah lewat
/// SQLite langsung. Halaman ini **tetap berfungsi penuh dalam mode pesawat**:
/// baca, tambah, edit, hapus, hanya sinkronisasinya yang ditahan.
class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  bool _syncing = false;

  Future<void> _syncNow() async {
    final offline = ref.read(forceOfflineProvider);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _syncing = true);
    try {
      final report =
          await ref.read(notesProvider.notifier).syncNow(offline: offline);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            offline
                ? '${report.message} — ${ref.read(dirtyCountProvider)} catatan menunggu online'
                : report.message,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _addNote() async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Catatan baru'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Judul',
                  hintText: 'mis. Belanja mingguan',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyController,
                minLines: 3,
                maxLines: 5,
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
    await ref.read(notesProvider.notifier).addNote(title: title, body: body);
  }

  Future<void> _confirmDelete(int? id, String title) async {
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus catatan?'),
        content: Text('"$title" akan dihapus dari SQLite perangkat ini.'),
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
    if (confirmed == true) {
      await ref.read(notesProvider.notifier).deleteNote(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesProvider);
    final dirtyCount = ref.watch(dirtyCountProvider);
    final offline = ref.watch(forceOfflineProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Offline'),
        actions: [
          if (offline)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Tooltip(
                message: 'Mode offline aktif',
                child: Icon(Icons.wifi_off_rounded, size: 20),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Badge(
              backgroundColor:
                  dirtyCount > 0 ? theme.colorScheme.error : theme.colorScheme.primary,
              label: Text(
                '$dirtyCount',
                style: TextStyle(color: theme.colorScheme.onError),
              ),
              child: IconButton(
                icon: const Icon(Icons.cloud_sync_outlined),
                tooltip: 'Antrean sinkronisasi: $dirtyCount catatan',
                onPressed: _syncing ? null : _syncNow,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          OfflineBanner(visible: offline),
          // Bar antrean diletakkan di atas daftar (bukan di bawah) agar tidak
          // tertimpa FloatingActionButton "Tulis".
          SyncQueueBar(
            dirtyCount: dirtyCount,
            total: notesAsync.value?.length ?? 0,
            syncing: _syncing,
            onSync: _syncNow,
            conflictRule: 'Last-Write-Wins (updated_at)',
          ),
          Expanded(
            child: notesAsync.when(
              // Data lama tetap tampil saat refresh (tanpa kedip loading).
              skipLoadingOnReload: true,
              loading: () => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Membaca database lokal…'),
                  ],
                ),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 44),
                      const SizedBox(height: 12),
                      Text(
                        'Gagal membaca database lokal.',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text('$error', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => ref.invalidate(notesProvider),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (notes) {
                if (notes.isEmpty) {
                  return _EmptyNotes(offline: offline);
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(notesProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 6, bottom: 96),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return NoteTile(
                        note: note,
                        onTap: note.id == null
                            ? null
                            : () => context.push('/note/${note.id}'),
                        onDelete: () => _confirmDelete(note.id, note.title),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNote,
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text('Tulis'),
      ),
    );
  }
}

class _EmptyNotes extends StatelessWidget {
  const _EmptyNotes({required this.offline});

  final bool offline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.note_alt_outlined, size: 56, color: theme.hintColor),
            const SizedBox(height: 12),
            Text('Belum ada catatan', style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Tekan tombol "Tulis" untuk membuat catatan pertama.\n'
              'Semuanya tersimpan di SQLite perangkat ini.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: 14),
            Chip(
              avatar: Icon(
                offline ? Icons.wifi_off_rounded : Icons.verified_rounded,
                size: 16,
              ),
              label: Text(
                offline ? 'Mode pesawat: tetap bisa menulis' : 'Tersimpan offline-first',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
