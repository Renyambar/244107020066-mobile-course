import 'package:flutter/material.dart';

import 'notes_page.dart';
import 'posts_page.dart';
import 'settings_page.dart';

/// Shell navigasi bawah: Catatan / Postingan / Pengaturan.
///
/// `IndexedStack` dipilih (bukan `StatefulShellRoute`) supaya state tiap tab —
/// posisi scroll, hasil refresh — tetap tersimpan saat berpindah tab.
/// Rute detail catatan (`/note/:id`) tetap ditangani GoRouter dan menimpa
/// shell ini.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          NotesPage(),
          PostsPage(),
          SettingsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.notes_outlined),
            selectedIcon: Icon(Icons.notes_rounded),
            label: 'Catatan',
          ),
          NavigationDestination(
            icon: Icon(Icons.cloud_outlined),
            selectedIcon: Icon(Icons.cloud_rounded),
            label: 'Postingan',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}
