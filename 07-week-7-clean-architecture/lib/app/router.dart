import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../routes.dart';
import '../features/announcements/presentation/pages/announcement_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import 'presentation/home_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Router dengan guard: belum login selalu diarahkan ke `/login`.
///
/// Terletak di `app/` karena menggabungkan halaman dari beberapa fitur
/// (composition root). Fitur sendiri tidak saling mengimpor widget.
GoRouter buildRouter(WidgetRef ref) => GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: AppRoutes.home,
      redirect: (context, state) {
        final loggedIn = ref.read(authStateProvider).value ?? false;
        final goingLogin = state.matchedLocation == AppRoutes.login;
        if (!loggedIn && !goingLogin) return AppRoutes.login;
        if (loggedIn && goingLogin) return AppRoutes.home;
        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.login,
          builder: (_, _) => const LoginPage(),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (_, _) => const HomePage(),
        ),
        GoRoute(
          path: '/pengumuman/:id',
          builder: (_, s) =>
              AnnouncementPage(id: s.pathParameters['id'] ?? ''),
        ),
      ],
    );
