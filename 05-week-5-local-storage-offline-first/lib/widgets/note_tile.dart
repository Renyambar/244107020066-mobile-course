import 'package:flutter/material.dart';

import '../data/local/note.dart';
import 'format.dart';

/// Refactoring #1 — baris catatan diextract menjadi widget tersendiri.
///
/// Menampilkan **badge "Belum tersinkron"** ketika `dirty == true`, sehingga
/// antrean sinkronisasi terlihat per baris, bukan hanya dari totalnya.
class NoteTile extends StatelessWidget {
  const NoteTile({super.key, required this.note, this.onTap, this.onDelete});

  final Note note;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dirty = note.dirty;

    return Dismissible(
      key: ValueKey('note-${note.id ?? note.title}-${note.updatedAt}'),
      direction: onDelete == null ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        color: theme.colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.delete_outline, color: theme.colorScheme.onErrorContainer),
      ),
      onDismissed: (_) => onDelete?.call(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: dirty
                ? theme.colorScheme.errorContainer
                : theme.colorScheme.primaryContainer,
            child: Text(
              note.id?.toString() ?? '#',
              style: theme.textTheme.labelLarge?.copyWith(
                color: dirty
                    ? theme.colorScheme.onErrorContainer
                    : theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          title: Text(
            note.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (note.body.isNotEmpty)
                Text(note.body, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    dirty ? Icons.cloud_off_outlined : Icons.cloud_done_outlined,
                    size: 13,
                    color: theme.hintColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formatDateTime(note.updatedAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (dirty)
                    Badge(
                      backgroundColor: theme.colorScheme.errorContainer,
                      textColor: theme.colorScheme.onErrorContainer,
                      smallSize: 6,
                      label: Text(
                        'Belum tersinkron',
                        style: theme.textTheme.labelSmall,
                      ),
                    )
                  else
                    Text(
                      'Tersinkron',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ],
          ),
          trailing: onDelete == null
              ? null
              : IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Hapus catatan',
                  onPressed: onDelete,
                ),
        ),
      ),
    );
  }
}
