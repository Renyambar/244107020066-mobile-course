import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../data/sync.dart';
import '../widgets/offline_banner.dart';

/// Langkah 2 (Provider + halaman pengaturan) — codelab Minggu 5.
///
/// Dua preferensi key-value: **tema gelap/terang** dan **waktu terakhir
/// dibuka**, keduanya hanya lewat `prefsRepositoryProvider`. Selain itu ada
/// toggle *force offline* (simulasi deterministik) dan ringkasan storage.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kosongkan data demo?'),
        content: const Text(
          'Semua catatan dihapus dari SQLite. Preferensi tema tetap tersimpan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Kosongkan'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(noteRepositoryProvider).deleteAllNotes();
      ref.invalidate(notesProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final darkAsync = ref.watch(darkModeProvider);
    final lastOpened = ref.watch(lastOpenedProvider);
    final offline = ref.watch(forceOfflineProvider);

    Widget section(String title) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
          child: Text(title, style: theme.textTheme.titleSmall),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          OfflineBanner(visible: offline),
          section('Preferensi — SharedPreferences'),
          darkAsync.when(
            skipLoadingOnReload: true,
            loading: () => const SwitchListTile(
              secondary: Icon(Icons.dark_mode_outlined),
              title: Text('Tema gelap'),
              subtitle: Text('Membaca kunci dark_mode…'),
              value: false,
              onChanged: null,
            ),
            error: (e, _) => ListTile(
              leading: const Icon(Icons.error_outline),
              title: const Text('Tema gelap gagal dibaca'),
              subtitle: Text('$e'),
            ),
            data: (dark) => SwitchListTile(
              secondary: Icon(
                dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              ),
              title: const Text('Tema gelap'),
              subtitle: Text(
                dark
                    ? 'Tema gelap aktif (kunci dark_mode = true)'
                    : 'Tema terang aktif (kunci dark_mode = false)',
              ),
              value: dark,
              onChanged: (_) =>
                  ref.read(darkModeProvider.notifier).toggle(),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.schedule_rounded),
            title: const Text('Terakhir dibuka'),
            subtitle: lastOpened.when(
              skipLoadingOnReload: true,
              loading: () => const Text('Membaca…'),
              error: (e, _) => Text('Gagal membaca: $e'),
              data: (iso) => Text(
                iso == null
                    ? 'Belum pernah dibuka (kunci last_opened_at kosong)'
                    : '${_format(iso)} — disimpan otomatis saat aplikasi start',
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Baca ulang preferensi',
              onPressed: () => ref.invalidate(lastOpenedProvider),
            ),
          ),
          section('Simulasi offline — deterministik'),
          SwitchListTile(
            secondary: const Icon(Icons.wifi_off_rounded),
            title: const Text('Paksa offline (forceOffline)'),
            subtitle: const Text(
              'Menonaktifkan jaringan secara logis: cache-first tetap membaca '
              'cache, sinkronisasi ditahan. Tidak perlu mematikan Wi-Fi.',
            ),
            value: offline,
            onChanged: (_) =>
                ref.read(forceOfflineProvider.notifier).toggle(),
          ),
          section('Jenis penyimpanan yang dipakai'),
          ListTile(
            leading: const Icon(Icons.storage_rounded),
            title: const Text('SQLite — sqflite'),
            subtitle: const Text(
              'Tabel notes (id, title, body, updated_at, dirty) dan '
              'cached_posts (id, payload, cached_at) untuk data koleksi.',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.tune_rounded),
            title: const Text('SharedPreferences'),
            subtitle: const Text(
              'Kunci dark_mode dan last_opened_at — hanya nilai primitif kecil.',
            ),
          ),
          section('Aturan konflik sinkronisasi'),
          ListTile(
            leading: const Icon(Icons.merge_type_rounded),
            title: Text(conflictRule),
            subtitle: const Text(
              'Saat data lokal dan server berubah, versi dengan updated_at '
              'paling baru yang menang — supaya sinkronisasi dua arah tidak '
              'menimpa data secara diam-diam.',
            ),
          ),
          section('Pembersihan'),
          ListTile(
            leading: Icon(Icons.delete_sweep_outlined,
                color: theme.colorScheme.error),
            title: const Text('Kosongkan data demo'),
            subtitle: const Text('Hapus semua catatan dari SQLite'),
            onTap: () => _confirmReset(context, ref),
          ),
        ],
      ),
    );
  }

  String _format(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}.${two(dt.minute)}';
  }
}
