import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'data/providers.dart';
import 'pages/home_shell.dart';
import 'pages/note_detail_page.dart';

/// Minggu 5 — Offline Notes (SharedPreferences + SQLite, offline-first).
///
/// `ProviderScope` membungkus aplikasi; tema dibaca dari `darkModeProvider`
/// (SharedPreferences) dan waktu terakhir dibuka dicatat saat aplikasi start.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Mode otomatisasi dokumentasi: buka aplikasi dengan `?semantics=true`
  // untuk mengaktifkan accessibility tree Flutter web, sehingga tool capture
  // (Playwright, `tool/capture.mjs`) bisa membaca & menekan tombol.
  if (Uri.base.queryParameters['semantics'] == 'true') {
    SemanticsBinding.instance.ensureSemantics();
  }

  runApp(const ProviderScope(child: OfflineNotesApp()));
}

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeShell(),
      ),
      GoRoute(
        path: '/note/:id',
        builder: (context, state) => NoteDetailPage(
          id: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
        ),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class OfflineNotesApp extends ConsumerStatefulWidget {
  const OfflineNotesApp({super.key});

  @override
  ConsumerState<OfflineNotesApp> createState() => _OfflineNotesAppState();
}

class _OfflineNotesAppState extends ConsumerState<OfflineNotesApp> {
  @override
  void initState() {
    super.initState();
    // Catat "terakhir dibuka" lewat repository (bukan SharedPreferences
    // langsung dari widget), lalu segarkan provider yang menampilkan waktu itu.
    Future.microtask(
      () => ref.read(lastOpenedProvider.notifier).markNow(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final darkMode = ref.watch(darkModeProvider).value ?? false;
    final router = ref.watch(routerProvider);

    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF3F51B5));

    return MaterialApp.router(
      title: 'Offline Notes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: scheme, useMaterial3: true),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3F51B5),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    );
  }
}
