import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/campus_app.dart';
import 'features/notifications/data/push_bootstrap.dart';
import 'features/notifications/presentation/providers/notifications_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Mode dokumentasi: `?semantics=true` menyalakan accessibility tree Flutter
  // web sehingga `tool/capture.mjs` (Playwright) bisa menggerakkan aplikasi lewat
  // `flt-semantics`, bukan koordinat layar yang mudah bergeser. Hanya berlaku di
  // web; perilaku Android/iOS tidak berubah.
  if (kIsWeb && Uri.base.queryParameters['semantics'] == 'true') {
    SemanticsBinding.instance.ensureSemantics();
  }

  // Pilih backend push (saat ini simulator; setelah FCM diintegrasikan sesuai
  // docs/fcm_integration.md, keputusan FCM-vs-simulator terjadi di sini).
  final gateway = await createPushGateway();

  runApp(
    ProviderScope(
      overrides: [pushGatewayProvider.overrideWithValue(gateway)],
      child: const CampusNotifyApp(),
    ),
  );
}
