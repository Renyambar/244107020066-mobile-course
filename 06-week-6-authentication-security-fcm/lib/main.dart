import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'messaging/background_handler.dart' as bg;
import 'messaging/bootstrap.dart';
import 'pages/announcement_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'providers/auth_provider.dart';
import 'providers/push_provider.dart';
import 'routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Mode dokumentasi: `?semantics=true` menyalakan accessibility tree Flutter
  // web sehingga `tool/capture.mjs` (Playwright) bisa menggerakkan aplikasi
  // lewat `flt-semantics`, bukan koordinat layar yang mudah bergeser.
  // Hanya berlaku di web; perilaku Android/iOS tidak berubah.
  if (kIsWeb && Uri.base.queryParameters['semantics'] == 'true') {
    SemanticsBinding.instance.ensureSemantics();
  }

  // Background handler WAJIB terdaftar sebelum runApp() dan berupa fungsi
  // top-level dengan @pragma('vm:entry-point') — lihat
  // lib/messaging/background_handler.dart.
  registerBackgroundHandlerSafely();

  // Pilih backend push: FCM asli bila Firebase sudah dikonfigurasi,
  // selain itu simulator (lihat lib/messaging/bootstrap.dart).
  final pushService = await bootstrapPushService();

  runApp(
    ProviderScope(
      overrides: [pushServiceProvider.overrideWithValue(pushService)],
      child: const CampusNotifyApp(),
    ),
  );
}

/// Daftarkan handler background hanya pada platform yang mendukung FCM asli.
void registerBackgroundHandlerSafely() {
  if (kIsWeb) return; // web memakai service worker terpisah
  // Pendaftaran dilakukan oleh FirebaseMessaging; fungsi ini menjaga agar
  // pemanggilan tidak crash saat Firebase belum terkonfigurasi.
  try {
    bg.registerBackgroundHandler();
  } catch (_) {
    // Firebase belum siap — simulator akan dipakai.
  }
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Router dengan guard: belum login selalu diarahkan ke `/login`.
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

class CampusNotifyApp extends ConsumerStatefulWidget {
  const CampusNotifyApp({super.key});

  @override
  ConsumerState<CampusNotifyApp> createState() => _CampusNotifyAppState();
}

class _CampusNotifyAppState extends ConsumerState<CampusNotifyApp> {
  late final GoRouter _router = buildRouter(ref);
  ProviderSubscription<AsyncValue<bool>>? _authSub;

  @override
  void initState() {
    super.initState();
    // Guard route: setiap perubahan status login memicu evaluasi ulang
    // `redirect` pada GoRouter.
    _authSub = ref.listenManual(authStateProvider, (_, _) {
      // Memicu evaluasi ulang `redirect` GoRouter.
      _router.refresh();
    });
  }

  @override
  void dispose() {
    _authSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Campus Notify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
