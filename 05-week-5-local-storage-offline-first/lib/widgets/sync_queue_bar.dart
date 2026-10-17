import 'package:flutter/material.dart';

/// Baris status di bawah daftar: jumlah antrean sinkronisasi + aturan konflik.
class SyncQueueBar extends StatelessWidget {
  const SyncQueueBar({
    super.key,
    required this.dirtyCount,
    required this.total,
    required this.syncing,
    required this.onSync,
    required this.conflictRule,
  });

  final int dirtyCount;
  final int total;
  final bool syncing;
  final VoidCallback onSync;
  final String conflictRule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final queued = dirtyCount > 0;

    return Material(
      color: queued
          ? theme.colorScheme.secondaryContainer
          : theme.colorScheme.surfaceContainerHighest,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          child: Row(
            children: [
              Icon(
                queued ? Icons.cloud_upload_outlined : Icons.cloud_done_outlined,
                size: 20,
                color: queued
                    ? theme.colorScheme.onSecondaryContainer
                    : theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      queued
                          ? 'Antrean sinkron: $dirtyCount dari $total catatan'
                          : 'Semua $total catatan tersinkron',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: queued
                            ? theme.colorScheme.onSecondaryContainer
                            : null,
                        fontWeight: queued ? FontWeight.w600 : null,
                      ),
                    ),
                    Text(
                      'Aturan konflik: $conflictRule',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: syncing ? null : onSync,
                icon: syncing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync_rounded, size: 18),
                label: Text(syncing ? 'Sinkron…' : 'Sinkronkan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
