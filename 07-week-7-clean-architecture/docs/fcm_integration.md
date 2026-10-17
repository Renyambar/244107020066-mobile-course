# Integrasi FCM (Firebase Cloud Messaging)

Aplikasi ini memisahkan **kontrak push notification** dari implementasinya:

- Kontrak (domain): `lib/features/notifications/domain/push_gateway.dart` → `PushGateway`
- Implementasi aktif (data): `lib/features/notifications/data/demo_push_gateway.dart` →
  `DemoPushGateway`, 100% offline, dipakai untuk demo & screenshot.
- Pabrik implementasi: `lib/features/notifications/data/push_bootstrap.dart` →
  `createPushGateway()`.

Untuk memakai FCM sungguhan, Anda hanya perlu menulis satu gateway baru dan menukar
pabriknya — **tanpa menyentuh presentation, use case, maupun entitas**. Justru inilah
yang diuji Clean Architecture-nya.

## 1. Tambah dependensi

```yaml
# pubspec.yaml
dependencies:
  firebase_core: ^3.6.0
  firebase_messaging: ^15.1.3
  flutter_local_notifications: ^17.2.2
```

Lalu:

```bash
flutter pub get
```

## 2. Siapkan proyek Firebase

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Perintah ini menghasilkan `lib/firebase_options.dart` dan konfigurasi platform
(`android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`, dst.).

Untuk Android, tambahkan plugin Google Services di `android/settings.gradle.kts`:

```kotlin
plugins {
    id("com.google.gms.google-services") version "4.4.2" apply false
}
```

Dan di `android/app/build.gradle.kts`:

```kotlin
plugins {
    id("com.google.gms.google-services")
}
```

## 3. Buat `FcmPushGateway`

Buat file baru (di luar folder fitur, misal `lib/services/fcm_push_gateway.dart`) agar
lapisan `lib/features/**` tetap steril dari `package:firebase_messaging`:

```dart
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:campus_notify/features/notifications/domain/push_gateway.dart';
import 'package:campus_notify/features/notifications/domain/push_message.dart';

/// Gateway push berbasis Firebase Cloud Messaging.
class FcmPushGateway implements PushGateway {
  FcmPushGateway(this._messaging);

  final FirebaseMessaging _messaging;

  static const _channel = AndroidNotificationChannel(
    'pengumuman_kampus',
    'Pengumuman Kampus',
    description: 'Notifikasi pengumuman kampus',
    importance: Importance.high,
  );

  final _local = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await _messaging.requestPermission();

    const settings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _local.initialize(
      const InitializationSettings(android: settings),
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Pesan saat aplikasi di foreground.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;
      _local.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    });
  }

  @override
  Future<Stream<PushMessage>> onMessage() async {
    return FirebaseMessaging.onMessage.map((message) {
      final notification = message.notification;
      return PushMessage(
        title: notification?.title ?? 'Pengumuman Kampus',
        body: notification?.body ?? '',
        announcementId: message.data['announcementId'] as String?,
        receivedAt: DateTime.now(),
      );
    });
  }

  @override
  Future<String?> getToken() => _messaging.getToken();

  @override
  Future<void> subscribeToCampusTopic() => _messaging.subscribeToTopic('campus_announcements');
}
```

## 4. Tukar pabriknya saja

Di `lib/features/notifications/data/push_bootstrap.dart`, ganti isi `createPushGateway()`:

```dart
PushGateway createPushGateway() {
  // return DemoPushGateway(); // implementasi demo (default)
  return FcmPushGateway(FirebaseMessaging.instance); // implementasi FCM
}
```

Selesai. Presentation (banner, dialog, navigasi), use case `RegisterDevice`, dan entitas
`PushMessage` tidak berubah sama sekali.

## 5. Catatan platform

- **Android**: `minSdkVersion` minimal 21 (sudah default Flutter), channel notifikasi
  dibuat saat bootstrap.
- **Web**: tambahkan `firebase_messaging` + service worker
  (`firebase-messaging-sw.js`) sesuai dokumentasi Firebase; `getToken()` untuk web
  membutuhkan VAPID key.
- **iOS**: jalankan sekali di simulator/perangkat untuk memunculkan izin notifikasi,
  lalu ambil APNs key di konsol Firebase.

## 6. Screenshot FCM (tugas Anda)

Setelah gateway FCM aktif, ambil screenshot sendiri, misalnya dengan emulator/perangkat
plus konsol Firebase Cloud Messaging:

1. Kirim pesan dari konsol Firebase → **Messaging → New campaign → Firebase Messaging API**.
2. Screenshot notifikasi diterima di perangkat/emulator (layout mobile).
3. Simpan sebagai `screenshots/after_fcm.png` lalu tautkan di README.

Screenshot yang sudah ada di folder ini (`before_*` dan `after_*`) dihasilkan lewat
jalur demo (`DemoPushGateway`) sehingga bisa direproduksi tanpa kredensial Firebase.
