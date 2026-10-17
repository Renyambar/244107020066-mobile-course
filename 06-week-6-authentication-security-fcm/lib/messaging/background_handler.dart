import 'package:firebase_messaging/firebase_messaging.dart';

/// Handler pesan FCM saat aplikasi berjalan di **background**.
///
/// WAJIB berupa fungsi top-level dengan `@pragma('vm:entry-point')`:
/// - Berjalan di isolate terpisah, sehingga tidak bisa menangkap variabel dari
///   UI.
/// - Dilarang mengakses `BuildContext`, Riverpod, atau plugin UI apa pun.
/// - Tugasnya hanya mencatat/menyimpan ringan. Navigasi dilakukan saat
///   pengguna mengklik banner (lihat `onMessageOpenedApp` / `getInitialMessage`).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Catatan: Firebase.initializeApp() harus sudah dipanggil di main() sebelum
  // runApp(); handler ini berjalan terpisah tetapi memakai isolate yang sama
  // dengan entry point aplikasi di Android/iOS.
  //
  // Isi handler dibatasi pada pekerjaan ringan non-UI, misalnya mencatat
  // penerimaan pesan untuk keperluan debug.
  // ignore: avoid_print
  print(
    '[bg-handler] pesan diterima id=${message.messageId} '
    'route=${message.data['route'] ?? '-'}',
  );
}

/// Daftarkan handler top-level ini ke Firebase Messaging.
///
/// Dipanggil sekali dari `main()` **sebelum** `runApp()`.
void registerBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}
