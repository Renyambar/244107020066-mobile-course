// PLACEHOLDER — file ini akan ditimpa oleh `flutterfire configure`.
//
// Jalankan perintah berikut untuk mengisinya dengan kredensial project Firebase
// milik Anda (lihat bagian "Cara Menjalankan" pada README):
//
//   dart pub global activate flutterfire_cli
//   firebase login
//   flutterfire configure --project=<id-project-anda> --platforms=android,web
//
// Selama [DefaultFirebaseOptions.currentPlatform] masih melempar
// `UnimplementedError`, `FcmPushService.create()` akan menangkapnya dan
// aplikasi otomatis berjalan dalam **mode simulasi push**
// (lihat `lib/messaging/demo_push_service.dart`) sehingga seluruh alur
// (token lifecycle, tiga app state, topic) tetap bisa didemonstrasikan
// tanpa kredensial Firebase.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Konfigurasi Firebase per platform.
///
/// Nilai sebenarnya ditulis oleh FlutterFire CLI. Jangan menaruh API key
/// produksi di repo publik tanpa membatasi key tersebut di Firebase Console.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // TODO(firebase): ganti baris di bawah dengan hasil `flutterfire configure`,
    // misalnya `return android;` / `return web;`.
    throw UnimplementedError(
      'DefaultFirebaseOptions belum dikonfigurasi. '
      'Jalankan `flutterfire configure` untuk mengisi file ini.',
    );
  }

  // Blok di bawah sengaja dibiarkan kosong. Setelah konfigurasi dijalankan,
  // FlutterFire akan menulis definisi Android/iOS/Web yang sebenarnya di sini.
  static final FirebaseOptions android = _notConfigured();
  static final FirebaseOptions ios = _notConfigured();
  static final FirebaseOptions web = _notConfigured();

  static FirebaseOptions _notConfigured() => throw UnimplementedError(
        'FirebaseOptions belum dikonfigurasi (jalankan flutterfire configure).',
      );
}
