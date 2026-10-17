# AI Challenge — Campus Notify (Minggu 6)

Dokumen ini mencatat **prompt**, **output awal AI**, **daftar perbaikan manual**,
dan **keputusan teknis** untuk bagian *AI Prompt Challenge* modul Minggu 6.
Kebijakan AI modul: AI boleh membuat implementasi awal FCM dan boilerplate auth,
tetapi mahasiswa **wajib memvalidasi token lifecycle, jenis payload, dan perilaku
notifikasi di tiga app state secara manual**. Nilai ada pada pembuktian perilaku
nyata (screenshot + log), bukan pada kode yang dihasilkan AI.

---

## 1. Prompt yang dipakai

Prompt dasar dari modul, saya perinci agar keluarannya langsung teruji dan tidak
menyembunyikan keputusan penting:

```
Aplikasi Flutter Campus Notification App.
Stack: firebase_messaging, flutter_local_notifications,
flutter_secure_storage, go_router, Riverpod.

Buatkan PushService dengan:
- requestPermission + getToken + onTokenRefresh (kirim ke POST /devices)
- onMessage (tampilkan local notification manual)
- onMessageOpenedApp + getInitialMessage (navigasi ke data.route)
- subscribe/unsubscribe topic pengumuman-kampus
- background handler top-level dengan @pragma('vm:entry-point')

Tandai bagian yang BERBEDA untuk Android 13+ vs iOS,
dan bagian yang tidak boleh mengakses BuildContext.

Syarat tambahan agar hasilnya teruji:
- Pisahkan kontrak PushService dari implementasinya, sehingga ada mode simulasi
  yang aktif otomatis ketika Firebase belum dikonfigurasi (untuk pengembangan &
  pengujian tanpa akun Firebase).
- Ekstrak parsing payload -> route ke fungsi murni routeFromMessage(data)
  dan tambahkan allow-list rute agar payload pihak ketiga tidak bisa
  mengarahkan pengguna sembarangan.
- Token FCM tidak pernah dicetak penuh ke log/UI; hanya 12 karakter + "...".
```

---

## 2. Output awal AI (draf) — ringkasan

AI menghasilkan kerangka berikut:

| Bagian | Isi draf |
|---|---|
| `TokenStore` | `FlutterSecureStorage` + `AndroidOptions(encryptedSharedPreferences: true)` |
| `AuthRepository` | mock login/refresh + komentar titik ganti Firebase Auth |
| `buildApiClient` | interceptor `onRequest` (Bearer) + `onError` (401 → refresh → retry) |
| `auth_provider` | `AsyncNotifier<bool>` + `authStateProvider` |
| `push_service` | FCM langsung: permission, token, 3 handler, topik |
| `background_handler` | top-level `@pragma('vm:entry-point')` |
| GoRouter | `redirect` guard `/login` ↔ `/` |
| `routeFromMessage` | `data['route'] ?? '/'` + tambah slash |

---

## 3. AI Verification Checklist (temuan & tindakan)

Checklist wajib modul beserta hasil verifikasi saya:

| # | Pertanyaan verifikasi | Hasil | Tindakan |
|---|---|---|---|
| 1 | Background handler fungsi top-level + `@pragma('vm:entry-point')`? | ✅ Ya | Diterima; dipindah ke `messaging/background_handler.dart` dan dibungkus `registerBackgroundHandlerSafely()` |
| 2 | `onTokenRefresh` benar-benar **mengirim** token baru ke backend, bukan hanya dicetak? | ⚠️ Draf hanya mencetak | Diperbaiki: `onTokenRefresh` → `DeviceApi.registerDevice()` → `POST /devices` |
| 3 | Foreground memakai local notification manual? | ⚠️ Belum lengkap | Diperbaiki: `showLocalNotificationPayload()` + in-app banner |
| 4 | Klik dari ketiga state masuk rute benar? | ⚠️ Belum diuji | Dibuktikan lewat tabel + screenshot `09`/`10`/`11` |
| 5 | Token/secret tidak di-hardcode & tidak di-log penuh? | ⚠️ Draf mencetak token penuh | Diperbaiki: `shortToken()` (12 karakter + `…`) di UI & log |

---

## 4. Daftar perbaikan manual (dan alasannya)

### A. Server tiruan 401 dipindah ke `HttpClientAdapter` — perbaikan terbesar

**Draf AI** menumpuk interceptor "server tiruan" *setelah* interceptor auth:

```dart
dio.interceptors.add(InterceptorsWrapper(
  onRequest: (options, handler) { ... handler.reject(401) ... },
));
```

**Masalah yang saya temukan saat menguji:** pada Dio 5.11, penolakan dari
interceptor yang ditambahkan **belakangan** tidak memicu `onError` interceptor
auth — sehingga 401 **tidak pernah sampai** ke logika refresh. Dampaknya alur
inti modul (401 → refresh → retry) tidak pernah terjadi, padahal kodenya
terlihat benar.

**Perbaikan:** server tiruan dipindah ke lapisan transport:

```dart
Dio buildDemoCampusApi(TokenStore store, AuthRepository auth) {
  final dio = buildApiClient(store, auth);
  dio.httpClientAdapter = _DemoCampusServer(); // menolak /me sekali (401)
  return dio;
}
```

Dengan adapter, request melewati interceptor **persis seperti jalur produksi**
lalu baru disintesis di lapisan transport. Diperkuat 2 unit test
(`DemoCampusApi — interceptor refresh diuji lewat jalur asli`), dan dibuktikan
di aplikasi: `401 → refresh sekali → retry 200 OK (Reny Ambarwati)` (screenshot `13`).

### B. Pesan hanya-data tidak boleh menampilkan banner

**Draf AI** memanggil `_showBanner(message)` untuk **setiap** `onMessage`.
Padahal tabel modul *Notification payload vs data payload* tegas: pesan
hanya-data **tidak ditampilkan otomatis**, hanya diteruskan ke handler.

**Perbaikan:** keputusan diambil lewat fungsi murni agar bisa diuji:

```dart
bool hasNotificationPayload({String? title, String? body}) =>
    title != null || body != null;
```

Dibuktikan di aplikasi (screenshot `12`: **tanpa banner**, hanya log) dan unit
test `payload hanya-data tidak layak menampilkan banner`.

### C. Allow-list rute untuk deep link

**Draf AI**: `routeFromMessage` meneruskan `data['route']` apa adanya. Payload
dari sumber luar bisa membawa `https://evil.example` atau `/admin/panel`.

**Perbaiki:** `route_parser.dart` menolak rute di luar allow-list
(`/`, `/login`, `/pengumuman/<angka>`) dan mengembalikannya ke halaman utama.
Diuji `router_guard_test.dart` (4 kasus penolakan).

### D. API `flutter_local_notifications` v22 (tidak kompilasi)

Draf memakai pemanggilan positional lama:

```dart
await _local.initialize(const InitializationSettings(...), onDidReceive...);
await _local.show(id, title, body, details, payload: route); // salah
```

Pada v22 signature-nya **named parameter**:

```dart
await localNotifications.initialize(
  settings: const InitializationSettings(android: android, iOS: ios), ...
);
await localNotifications.show(
  id: ..., title: ..., body: ..., notificationDetails: ..., payload: ...,
);
```

### E. API paket lain yang berubah sejak draf

| Paket | Draf AI | Kenyataan di versi terpasang | Perbaikan |
|---|---|---|---|
| `flutter_secure_storage` ^11 | `AndroidOptions(encryptedSharedPreferences: true)` | parameter **dihapus** | `const FlutterSecureStorage()` |
| `dio` ^5.11 | switch `DioExceptionType` | ada `transformTimeout` | ditambahkan agar switch ekshaustif |
| `flutter_riverpod` ^3 | `WidgetRef.listen` mengembalikan subscription | `WidgetRef.listen` → `void`; pakai `listenManual` | `ref.listenManual(authStateProvider, ...)` → `_router.refresh()` |

### F. Keamanan token di UI & log

Draf mencetak token penuh. Saya tambahkan `shortToken()` (12 karakter + `…`)
di `device_api.dart` dan memakainya di status card maupun log `POST /devices`.
Token penuh **tidak pernah** muncul di screenshot laporan.

---

## 5. Keputusan teknis (boleh berbeda dari saran AI)

### Keputusan 1 — Dua implementasi `PushService`, satu kontrak

Lingkungan pengembangan ini belum memiliki konfigurasi Firebase. Alih-alih
menghapus kode FCM, saya menarik **kontrak** `PushService` lalu menyediakan dua
implementasi:

| Implementasi | Aktif ketika |
|---|---|
| `FcmPushService` (`fcm_push_adapter.dart`) | `Firebase.initializeApp()` berhasil |
| `DemoPushService` (`demo_push_service.dart`) | Firebase belum terkonfigurasi |

`bootstrap.dart` memilih otomatis. **Alasan:** seluruh alur (token lifecycle,
tiga app state, topik, deep link) tetap bisa didemonstrasikan dan diuji di
lingkungan tanpa Firebase, sementara migrasi ke FCM asli hanya butuh
`flutterfire configure` — **tanpa mengubah satu baris pun di UI/provider**.
Ini juga membuat logika *di sekitar* Firebase (parsing route, sesi, interceptor)
benar-benar teruji unit test, sesuai arahan modul bahwa "Firebase tidak diuji
langsung".

### Keputusan 2 — Guard route di-refresh lewat `listenManual`, bukan `refreshListenable`

Draf memakai `ChangeNotifier` pembungkus untuk `refreshListenable`. Pada
Riverpod 3.x `WidgetRef.listen` tidak mengembalikan subscription, jadi pola itu
rapuh. Saya pakai `ref.listenManual(authStateProvider, ...)` di `initState`
`ConsumerStatefulWidget` lalu memanggil `_router.refresh()` — lebih eksplisit dan
tidak menyembunyikan lifecycle listener.

### Keputusan 3 — Test interceptor memakai `HttpClientAdapter`, bukan interceptor

Sama alasan dengan perbaikan A: menumpuk interceptor membuat pengujian tidak
mewakili jalur produksi. Dengan adapter, unit test menguji **interceptor auth
yang asli**.

---

## 6. Bug FCM yang paling mahal — dan bagaimana dicegah

| Bug | Gejala | Pencegahan di proyek ini |
|---|---|---|
| Token basi | Notifikasi berhenti tanpa error | `onTokenRefresh` → `POST /devices` (bukan sekadar log) |
| Klik nyasar | Notifikasi membuka halaman salah | allow-list rute + `routeFromMessage` murni (diuji) |
| Banner ganda | Banner sistem + banner manual muncul bersamaan | banner manual hanya untuk payload ber-`notification` |
| Refresh berputar | 401 → refresh → 401 → refresh… tanpa henti | penanda `X-Auth-Retry` + test anti-loop |

---

## 7. Rencana migrasi ke Firebase Auth + FCM asli

1. `dart pub global activate flutterfire_cli` lalu
   `flutterfire configure --project=<id-proyek>` → menulis
   `lib/firebase_options.dart` + `google-services.json`.
2. Di Firebase Console: tambah aplikasi Android dengan package name
   `com.renyambar.campus_notify`, unduh `google-services.json` ke `android/app/`.
3. `AuthRepository.login()` diganti `FirebaseAuth.instance.signInWithEmailAndPassword`
   / `signInWithGoogle` — pola repository & refresh token tetap identik.
4. Uji kirim pertama dari **Firebase Console → Messaging** pada state
   background, lalu catat sebagai `screenshots/fcm-console-test.png`.
5. Untuk web: buat *web app* di console + VAPID key + `firebase-messaging-sw.js`.
