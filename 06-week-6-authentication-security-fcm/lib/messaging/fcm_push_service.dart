import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'route_parser.dart';

/// Plugin notifikasi lokal — hanya tersedia di Android/iOS.
final FlutterLocalNotificationsPlugin localNotifications =
    FlutterLocalNotificationsPlugin();

/// Rute yang menunggu tindakan pengguna (klik banner foreground).
///
/// Diisi oleh [initLocalNotifications] saat pengguna menekan banner yang
/// ditampilkan lewat local notification, lalu dikonsumsi GoRouter.
String? pendingDeepLink;

/// Inisialisasi notifikasi lokal (modul langkah 2 — permintaan izin).
Future<bool> requestNotificationPermission() async {
  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    announcement: false,
    carPlay: false,
    criticalAlert: false,
  );
  return settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional;
}

/// Siapkan local notification untuk menampilkan banner saat **foreground**.
///
/// Android menampilkan notifikasi otomatis hanya saat app background/terminated.
/// Saat app terbuka, sistem *tidak* menampilkan banner apa pun, jadi kita
/// harus menampilkannya sendiri lewat plugin ini.
Future<void> initLocalNotifications() async {
  if (kIsWeb) return; // plugin lokal tidak didukung di web
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings();
  await localNotifications.initialize(
    settings: const InitializationSettings(android: android, iOS: ios),
    onDidReceiveNotificationResponse: (response) {
      // Klik banner foreground -> teruskan payload ke router.
      pendingDeepLink = response.payload;
    },
  );
}

/// Tampilkan notifikasi lokal untuk pesan foreground.
Future<void> showLocalNotification(RemoteMessage message) =>
    showLocalNotificationPayload(
      title: message.notification?.title,
      body: message.notification?.body,
      route: routeFromMessage(message.data),
    );

/// Versi yang menerima data sudah diparsing — dipakai adapter FCM dan simulator.
Future<void> showLocalNotificationPayload({
  required String? title,
  required String? body,
  required String route,
}) async {
  if (kIsWeb) return; // flutter_local_notifications tidak mendukung web
  const androidDetails = AndroidNotificationDetails(
    'pengumuman',
    'Pengumuman Kampus',
    importance: Importance.high,
    priority: Priority.high,
  );
  await localNotifications.show(
    id: DateTime.now().microsecondsSinceEpoch,
    title: title ?? 'Pengumuman',
    body: body ?? '',
    notificationDetails: const NotificationDetails(android: androidDetails),
    payload: route,
  );
}

/// Inisialisasi FCM: ambil token, kirim ke backend, dan pantau rotasi.
///
/// Urutan wajib modul:
/// 1. `getToken()` → kirim ke backend.
/// 2. `onTokenRefresh` → kirim ulang (tanpa ini backend menyimpan token basi).
/// 3. `subscribeToTopic()` untuk broadcast kampus.
Future<String?> initFcmToken({
  required Future<void> Function(String token) onToken,
  String topic = 'pengumuman-kampus',
}) async {
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) await onToken(token);

  FirebaseMessaging.instance.onTokenRefresh.listen(onToken);

  await FirebaseMessaging.instance.subscribeToTopic(topic);
  return token;
}

/// Ambil registration token FCM.
Future<String?> getFcmToken() => FirebaseMessaging.instance.getToken();

/// Berhenti dari topik broadcast.
Future<void> unsubscribeFcmTopic(String topic) =>
    FirebaseMessaging.instance.unsubscribeFromTopic(topic);

/// Dengarkan pesan foreground (`onMessage`) dan klik background (`onMessageOpenedApp`).
void listenForeground(void Function(String route) go) {
  FirebaseMessaging.onMessage.listen((message) async {
    await showLocalNotification(message);
  });

  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    go(routeFromMessage(message.data));
  });
}

/// Tangani pesan yang membuka aplikasi dari kondisi **terminated**.
Future<void> handleTerminated(void Function(String route) go) async {
  final initial = await FirebaseMessaging.instance.getInitialMessage();
  if (initial != null) go(routeFromMessage(initial.data));
  if (pendingDeepLink != null) {
    go(pendingDeepLink!);
    pendingDeepLink = null;
  }
}

/// Apakah platform ini layak memakai FCM asli.
///
/// FCM asli butuh: (a) platform mobile ATAU web yang sudah dikonfigurasi
/// FlutterFire, dan (b) `firebase_options.dart` valid. Pemanggilan
/// [isFcmSupported] hanya mengecek platform; ketersediaan konfigurasi dicek
/// terpisah saat bootstrap.
bool isFcmSupportedPlatform() {
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}
