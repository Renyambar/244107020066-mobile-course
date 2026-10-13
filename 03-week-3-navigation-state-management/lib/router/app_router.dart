import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../pages/detail_page.dart';
import '../pages/stats_page.dart';
import '../pages/todo_page.dart';

/// Konfigurasi GoRouter dengan StatefulShellRoute agar state tab tetap terjaga
/// saat berpindah antara tab Tugas dan Statistik
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.checklist_rtl_rounded),
                selectedIcon: Icon(Icons.checklist_rounded),
                label: 'Tugas ToDo',
              ),
              NavigationDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(Icons.analytics_rounded),
                label: 'Statistik',
              ),
            ],
          ),
        );
      },
      branches: [
        // Branch 1: Halaman Daftar ToDo dan Sub-rute Detail
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const TodoPage(),
              routes: [
                GoRoute(
                  path: 'detail/:id',
                  builder: (context, state) {
                    final id = state.pathParameters['id'] ?? '1';
                    final title = state.uri.queryParameters['title'];
                    final done = state.uri.queryParameters['done'] == 'true';
                    return DetailPage(
                      id: id,
                      initialTitle: title,
                      initialDone: done,
                    );
                  },
                ),
              ],
            ),
          ],
        ),

        // Branch 2: Halaman Statistik (/stats)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/stats',
              builder: (context, state) => const StatsPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);
