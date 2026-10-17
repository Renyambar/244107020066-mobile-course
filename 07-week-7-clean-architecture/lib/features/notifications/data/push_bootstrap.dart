import '../domain/repositories/push_gateway.dart';
import 'sources/demo_push_gateway.dart';

/// Memilih implementasi [PushGateway] yang dipakai aplikasi saat startup.
///
/// Saat ini selalu memakai simulator [DemoPushGateway] sehingga codelab berjalan
/// tanpa kredensial Firebase. Setelah integrasi FCM pada `docs/fcm_integration.md`
/// diterapkan, fungsi ini menjadi tempat tunggal pemilihan backend:
///
/// ```dart
/// try {
///   return await FcmPushGateway.create(); // adapter FCM asli
/// } on FirebaseInitializationException {
///   return DemoPushGateway();             // fallback simulator
/// }
/// ```
///
/// Inilah penerapan Open/Closed: menukar backend tidak menyentuh UI sama sekali.
Future<PushGateway> createPushGateway() async => DemoPushGateway();
