import 'fcm_push_adapter.dart';
import 'push_service.dart';
import 'demo_push_service.dart';

/// Memilih implementasi [PushService] yang akan dipakai aplikasi.
///
/// Urutan keputusan:
/// 1. Coba inisialisasi **FCM asli** (`FcmPushService.create()`).
///    - Berhasil  -> memakai Firebase Cloud Messaging sungguhan.
///    - Gagal     -> `FirebaseInitializationException` (belum ada
///                   `firebase_options.dart` valid) -> lanjut ke langkah 2.
/// 2. Pakai **simulasi** (`DemoPushService`) supaya alur token lifecycle,
///    tiga app state, dan topik tetap dapat didemonstrasikan tanpa kredensial.
///
/// Keputusan ini dibuat sekali saat startup dan di-override ke dalam
/// Riverpod, sehingga UI tidak perlu mengecek platform berulang kali.
Future<PushService> bootstrapPushService() async {
  try {
    return await FcmPushService.create();
  } on FirebaseInitializationException {
    return DemoPushService();
  } catch (_) {
    // Kegagalan tak terduga (mis. Firebase tidak tersedia di platform ini)
    // tetap jatuh ke simulator agar aplikasi tetap bisa dipakai.
    return DemoPushService();
  }
}
