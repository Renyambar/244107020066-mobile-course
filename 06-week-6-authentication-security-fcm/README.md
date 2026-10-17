# Minggu 6: Authentication, Security & FCM

Laporan tugas praktikum Minggu 6 mata kuliah Pemrograman Mobile, mengikuti
codelab resmi [Minggu 6 — Authentication, Security & FCM](https://jti-polinema.github.io/flutter-codelab/06-minggu-6-authentication-security-fcm/index.html)
(JTI Polinema) beserta *Mini Project / Industry Challenge* di dalamnya.

Aplikasi **Campus Notify** mengimplementasikan alur autentikasi lengkap:
penyimpanan token di *secure storage*, interceptor Dio yang melakukan **refresh
otomatis sekali saat 401**, guard route dengan GoRouter, serta integrasi
**Firebase Cloud Messaging (FCM)** — permission, *token lifecycle*
(`getToken` + `onTokenRefresh` → `POST /devices`), *topic messaging*, deep link
dari notifikasi pada **tiga app state** (foreground, background, terminated),
dan prinsip keamanan dasar (token tidak pernah di-log penuh / disimpan di
`SharedPreferences`).

## Identitas Mahasiswa

- **Nama:** Reny Ambarwati
- **NIM:** 244107020066
- **Kelas:** TI-3F
- **Mata Kuliah:** Pemrograman Mobile

---

## Tujuan Pembelajaran

1. Menjelaskan alur autentikasi (Firebase Auth / JWT / OAuth) dan perbedaan
   *ID token* vs *access token* vs *refresh token*.
2. Menyimpan token secara aman dengan *secure storage* serta menerapkan
   *token refresh* otomatis.
3. Menjelaskan arsitektur FCM: app server → Firebase → perangkat.
4. Meminta *notification permission* dan mengelola *token lifecycle*
   (`getToken`, `onTokenRefresh`).
5. Membedakan *notification payload* vs *data payload* serta perilakunya pada
   state *foreground*, *background*, dan *terminated*.
6. Menangani klik notifikasi (deep link dengan GoRouter) dan *topic messaging*.
7. Menerapkan prinsip keamanan dasar: tidak menyimpan secret di kode, tidak
   mencetak token ke log.

## Stack Teknologi

| Komponen | Versi | Keterangan |
|---|---|---|
| Flutter (Dart) | 3.47.1 (3.13.1) | channel stable |
| `flutter_riverpod` | ^3.4.3 | state management (`AsyncValue`) |
| `go_router` | ^18.1.0 | routing + guard + deep link |
| `dio` | ^5.11.1 | HTTP client + interceptor refresh 401 |
| `flutter_secure_storage` | ^11.2.0 | Keychain / Keystore untuk token |
| `firebase_core` | ^4.15.0 | inisialisasi Firebase |
| `firebase_messaging` | ^16.7.0 | FCM: permission, token, pesan |
| `flutter_local_notifications` | ^22.3.2 | banner manual saat foreground |
| `flutter_test` | SDK | unit test tanpa Firebase sungguhan |

**Application ID:** `com.renyambar.campus_notify` (konsisten dengan pola
`com.renyambar.*` pada minggu-minggu sebelumnya).

## Struktur Folder

```
06-week-6-authentication-security-fcm/
├── lib/                             # Project Flutter (bisa dijalankan)
│   ├── main.dart                    # bootstrap + GoRouter guard + listener auth
│   ├── routes.dart                  # Refactoring #1: konstanta rute terpusat
│   ├── firebase_options.dart        # placeholder (diisi flutterfire configure)
│   ├── data/
│   │   ├── token_store.dart         # Langkah 1: satu-satunya pintu token
│   │   ├── auth_repository.dart     # Langkah 2: mock auth + titik ganti Firebase
│   │   ├── api_client.dart          # Langkah 3: interceptor 401 → refresh → retry
│   │   ├── api_errors.dart          # Refactoring #3: DioException → pesan ramah
│   │   ├── device_api.dart          # kontrak POST /devices (+MockDeviceApi)
│   │   └── demo_campus_api.dart     # server tiruan GET /me (401 sekali lalu 200)
│   ├── providers/
│   │   ├── auth_provider.dart       # Langkah 4: authStateProvider (AsyncNotifier)
│   │   └── push_provider.dart       # PushState: permission, token, log event
│   ├── messaging/
│   │   ├── push_service.dart        # kontrak PushService + PushMessage + model
│   │   ├── demo_push_service.dart   # simulator (aktif saat Firebase belum ada)
│   │   ├── fcm_push_service.dart    # implementasi FCM asli
│   │   ├── fcm_push_adapter.dart    # adapter FCM + deteksi ketersediaan Firebase
│   │   ├── background_handler.dart  # top-level @pragma('vm:entry-point')
│   │   ├── bootstrap.dart           # pilih FCM asli vs simulator
│   │   └── route_parser.dart        # Refactoring #2: routeFromMessage (murni)
│   └── pages/                       # login_page, home_page, announcement_page
├── test/
│   ├── auth_push_test.dart          # 23 test: parsing route, sesi/refresh, dsb.
│   ├── router_guard_test.dart       # allow-list rute deep link
│   └── widget_test.dart             # konsistensi konstanta rute
├── tool/
│   ├── capture.mjs                  # Playwright: screenshot layout mobile 390x844
│   ├── serve.mjs                    # server statis build/web (tanpa dependensi)
│   ├── mobile_harness.html          # bingkai 390x844 untuk pratinjau manual
│   └── package.json                 # playwright-core
├── docs/
│   ├── ai_challenge.md              # prompt, output AI, perbaikan manual
│   └── device_endpoint.md           # kontrak POST /devices
├── screenshots/                     # 14 bukti screenshot (390x844)
└── README.md
```

> Berbeda dengan minggu 4/5 (yang memakai subfolder `weekN_x/`), project Minggu 6
> diletakkan **langsung di root** — mengikuti struktur folder yang diminta modul
> (`lib/`, `test/`, `docs/`, `screenshots/`, `README.md`).

---

## Catatan Penting: Mode Demo vs FCM Asli

Lingkungan pengembangan ini **belum memiliki konfigurasi Firebase**
(`google-services.json` / `firebase_options.dart` valid, Firebase CLI belum
login). Agar seluruh alur tetap dapat didemonstrasikan dan diuji, aplikasi
memakai dua implementasi di balik **kontrak `PushService` yang sama**:

| Implementasi | File | Aktif ketika |
|---|---|---|
| `FcmPushService` | `messaging/fcm_push_adapter.dart` | Firebase berhasil diinisialisasi |
| `DemoPushService` | `messaging/demo_push_service.dart` | Firebase belum terkonfigurasi |

`bootstrap.dart` memutuskan otomatis. **Seluruh kode FCM asli sudah lengkap**
(permission, `getToken`, `onTokenRefresh`, `onMessage`,
`onMessageOpenedApp`, `getInitialMessage`, topik, background handler) — hanya
perlu diisi konfigurasi Firebase untuk mengaktifkannya tanpa mengubah UI sama
sekali. Simulator meniru perilaku FCM (termasuk rotasi token dan tiga app
state) sehingga screenshot bukti tetap valid secara **alur**, dan seluruh logika
sekitar Firebase (parsing route, sesi, interceptor) tetap teruji unit test.

---

## Arsitektur & Alur

### Alur autentikasi

```
Login --> access (15 mnt) + refresh (7 hari) tersimpan aman (Secure Storage)
Request API --header Bearer access--> 401 expired?
                                          | Ya
                                          v
                              tarik refresh --> access baru
                                          | 
                                          v
                                ulangi request SEKALI
Refresh ikut kedaluwarsa --> clear() --> paksa login ulang (/login)
```

### Alur FCM

```
App Server (backend) --kirim ke--> Firebase Cloud Messaging
FCM --push--> Perangkat Android / iOS
Aplikasi --daftar token--> Backend (POST /devices, simpan token per user)
```

### Pemetaan tiga app state

| State | Arti | Handler yang bekerja | Bukti |
|---|---|---|---|
| Foreground | Aplikasi terbuka | `onMessage` → tampil manual | `08`, `09` |
| Background | Aplikasi diminimize | banner sistem + `onMessageOpenedApp` | `10` |
| Terminated | Aplikasi dimatikan | `getInitialMessage()` saat dibuka | `11` |

---

## Langkah 1 — Penyimpanan token yang aman

Seluruh token hanya keluar-masuk lewat `lib/data/token_store.dart`
(`flutter_secure_storage` → Keychain/Keystore), **bukan** `SharedPreferences`.

```dart
class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();
  ...
  Future<void> save({required String access, required String refresh}) async {
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }
}
```

**Output:**

```
flutter pub add flutter_secure_storage
  + flutter_secure_storage 11.2.0
```

> **Penyesuaian terhadap paket:** pada `flutter_secure_storage` v11 parameter
> `AndroidOptions(encryptedSharedPreferences: true)` sudah **dihapus** —
> enkripsi SharedPreferences lama diganti mekanisme Keystore bawaan paket.
> Kode disederhanakan menjadi `const FlutterSecureStorage()`.

## Langkah 2 — Repository auth (mock siap diganti Firebase Auth)

`AuthRepository.login()` memvalidasi bentuk email & panjang sandi, lalu
menghasilkan sepasang token simulasi; `refresh()` menukar refresh token lama
dengan access token baru. Method `login()` adalah **titik ganti tunggal** ke
`FirebaseAuth.instance.signInWithEmailAndPassword` / `signInWithGoogle`.

```dart
Future<AuthSession> login({required String email, required String password}) async {
  await Future<void>.delayed(loginLatency);
  if (!email.contains('@') || password.length < 6) {
    throw const AuthException('Email atau kata sandi tidak valid');
  }
  ...
}
```

**Output (validasi form — screenshot `02`):**

```
Email tidak valid
minimal 6 karakter
```

## Langkah 3 — Dio dengan refresh otomatis saat 401

Interceptor di `lib/data/api_client.dart` menempelkan `Authorization: Bearer`
lalu menangkap 401: tukar refresh token, **ulangi request yang sama satu kali**,
dan bila refresh ikut mati → `clear()` (paksa login ulang). Penanda
`X-Auth-Retry` dipakai agar **tidak berputar 401 tanpa henti**.

```dart
onError: (e, handler) async {
  final alreadyRetried = e.requestOptions.extra['X-Auth-Retry'] == true;
  if (e.response?.statusCode == 401 && !alreadyRetried) { ... }
}
```

**Output (unit test + aplikasi):**

```
+2: test/auth_push_test.dart : 401 pertama memicu refresh lalu retry sukses 200
+1: test/auth_push_test.dart : refresh mati -> sesi dibersihkan dan 401 diteruskan
+1: test/auth_push_test.dart : 401 kedua tidak memicu refresh ulang (anti-loop)
```

**Bukti di aplikasi (screenshot `13`):**

```
401 → refresh sekali → retry 200 OK (Reny Ambarwati)
```

> **Temuan yang saya perbaiki:** draf awal menumpuk interceptor "server tiruan"
> di atas interceptor auth. Ternyata pada Dio 5.11 penolakan dari interceptor
> yang ditambahkan **belakangan** tidak memicu `onError` interceptor auth, sehingga
> 401 tidak pernah sampai ke logika refresh. Saya pindahkan server tiruan ke
> `HttpClientAdapter` (`demo_campus_api.dart`), sehingga request melewati
> interceptor **persis jalur produksi** lalu disintesis di lapisan transport.
> Diperkuat 2 unit test baru. Detail di [`docs/ai_challenge.md`](docs/ai_challenge.md).

## Langkah 4 — Provider auth + guard route

`authStateProvider` (`AsyncNotifier<bool>`) membaca status login dari token.
GoRouter di `main.dart` memakai `redirect` yang mengarahkan belum-login ke
`/login` selamanya, plus `ref.listenManual` → `router.refresh()` agar guard
berjalan ulang setiap status auth berubah (login/logout/refresh gagal).

```dart
redirect: (context, state) {
  final loggedIn = ref.read(authStateProvider).value ?? false;
  final goingLogin = state.matchedLocation == AppRoutes.login;
  if (!loggedIn && !goingLogin) return AppRoutes.login;
  if (loggedIn && goingLogin) return AppRoutes.home;
  return null;
},
```

**Bukti guard route:** aplikasi selalu membuka `/login` ketika token kosong
(screenshot `01`), masuk ke `/` setelah login (`03`), dan kembali ke `/login`
setelah `Keluar` (`14`).

---

## Langkah 5 — Permission & token lifecycle

`requestPermission()` (Android 13+/iOS wajib runtime), lalu `getToken()` →
kirim ke backend `POST /devices`. Listener `onTokenRefresh` **wajib** ada:
tanpa itu backend menyimpan token basi setelah reinstall/rotasi keamanan.

**Bukti (screenshot `04`):**

```
Token FCM            fcm_sim_nn77…      ← terpotong (12 karakter + …)
Terdaftar di backend ya
Log POST /devices    POST /devices → 200 (fcm_sim_nn77…)
```

**Bukti rotasi (screenshot `05`) — token berubah, listener kirim ulang:**

```
onTokenRefresh → POST /devices (fcm_sim_nqtt…)
getToken → fcm_sim_nn77…
```

> Token ditampilkan **hanya 12 karakter pertama + `…`** (`shortToken()`), dan
> log memakai token terpotong — token penuh tidak pernah muncul di screenshot
> maupun log, sesuai prinsip keamanan modul.

## Langkah 6 — Notification vs data payload & tiga app state

Payload gabungan dipakai selalu: `notification` untuk teks yang dibaca manusia,
`data.route` untuk tujuan deep link.

```json
{
  "message": {
    "topic": "pengumuman-kampus",
    "notification": {
      "title": "Jadwal kuliah berubah",
      "body": "Kelas Mobile pindah ke Ruang A2 jam 13.00"
    },
    "data": { "route": "/pengumuman/3", "id": "3" }
  }
}
```

**Matriks pengujian (payload yang sama untuk ketiga state):**

| State | Yang diharapkan | Cara uji | Hasil | Bukti |
|---|---|---|---|---|
| Foreground | Banner **lokal** muncul, klik → `/pengumuman/3` | Aplikasi terbuka, kirim | ✅ banner in-app muncul; klik membuka `#3` | `08`, `09` |
| Background | Banner **sistem**, klik → rute benar | Tekan Home, kirim, klik banner | ✅ klik membuka `/pengumuman/2` | `10` |
| Terminated | Aplikasi terbuka ke rute benar via `getInitialMessage()` | Swipe-close, kirim, klik banner | ✅ dibuka langsung ke `/pengumuman/1` | `11` |

**Pembuktian pemisahan payload (screenshot `12`):** pesan **hanya-data** tidak
menampilkan banner apa pun, hanya tercatat di log — sesuai tabel modul.
Keputusan ini diekstrak ke fungsi murni agar bisa diuji:

```dart
bool hasNotificationPayload({String? title, String? body}) =>
    title != null || body != null;
```

## Langkah 7 — Background handler & topic messaging

Handler background harus **fungsi top-level** dengan
`@pragma('vm:entry-point')` karena berjalan di isolate terpisah — bukan method
kelas, dan tidak boleh mengakses `BuildContext`/Riverpod
(`messaging/background_handler.dart`).

Topik dipakai untuk **broadcast**, token perangkat untuk **pesan personal**:

**Topik aktif (screenshot `06`):** switch ON → `Berlangganan broadcast kampus`
**Topik nonaktif (screenshot `07`):** log memperlihatkan urutan
`subscribeToTopic` → `unsubscribeFromTopic("pengumuman-kampus")`

---

## Refactoring Challenge (semua dikerjakan)

| # | Tantangan modul | Implementasi | Keuntungan |
|---|---|---|---|
| 1 | Pindahkan semua string rute ke `lib/routes.dart` | `AppRoutes.login/home/announcement(id)`, `isAllowed()`, `isAnnouncement()` | Deep link FCM & GoRouter memakai konstanta yang sama |
| 2 | Ekstrak parsing `RemoteMessage` → route ke fungsi murni | `routeFromMessage()`, `announcementIdFromMessage()`, `hasNotificationPayload()` di `route_parser.dart` | Bisa diunit-test tanpa Firebase |
| 3 | Pemetaan `DioException` → pesan ramah ke `api_errors.dart` | `apiErrorMessage(e)` menangani 401, timeout, offline, dsb. | UI hanya menerima pesan, bukan exception mentah |

Refactoring #2 juga dilengkapi **allow-list**: rute di luar daftar
(`/admin/panel`, URL absolut, id non-numerik) ditolak kembali ke halaman utama,
sehingga payload dari pihak ketiga tidak bisa mengarahkan pengguna sembarangan
(diuji di `router_guard_test.dart`).

---

## Testing: unit test tanpa Firebase sungguhan

Firebase tidak diuji langsung; yang diuji adalah **logika di sekitarnya**:
parsing route, logika sesi/refresh, kontrak `POST /devices`, dan guard route.

```sh
flutter analyze
flutter test
```

**Output `flutter analyze`:**

```
Analyzing 06-week-6-authentication-security-fcm...
No issues found! (ran in 7.5s)
```

**Output `flutter test`:**

```
00:03 +23: All tests passed!
```

Kelompok test yang tersedia:

| Kelompok | Menguji |
|---|---|
| `routeFromMessage` | route kosong, tanpa slash, allow-list, id pengumuman |
| `hasNotificationPayload` | payload hanya-data tidak boleh menampilkan banner |
| `AuthRepository` | login sukses/gagal, refresh token kosong |
| `TokenStore` (fake) | status login, refresh gagal → sesi dibersihkan |
| Interceptor Dio | 401→refresh→retry, refresh mati, anti-loop |
| `DemoCampusApi` | interceptor asli lewat `HttpClientAdapter` |
| `MockDeviceApi` | kontrak `POST /devices`, token ditampilkan terpotong |
| Provider auth | guard route: awalnya belum login |

Test memakai `FakeTokenStore` + `HttpClientAdapter` tiruan, sehingga **tidak ada
request jaringan sungguhan** di dalam test.

---

## Cara Menjalankan

```sh
cd 06-week-6-authentication-security-fcm
flutter pub get
flutter run            # buka di Chrome/Edge, atur ukuran ke mobile
```

Aplikasi membuka `/login` (guard route). Kredensial mock sudah terisi otomatis:
`demo@kampus.test` / `rahasia123`. Setelah masuk, kartu **Simulator Push**
menyediakan tombol untuk mendemonstrasikan permission, token lifecycle, rotasi,
tiga app state, topik, dan uji 401.

**Mengambil screenshot layout mobile** (dipakai untuk dokumentasi ini):

```sh
flutter build web --release --no-wasm-dry-run
node tool/serve.mjs 8081                              # sajikan build/web
cd tool && npm install                                # playwright-core
node capture.mjs login ../screenshots/01-login.png    # SATU skenario per perintah
node capture.mjs probe                                 # dump accessibility tree
```

`capture.mjs` menjalankan **satu skenario → satu screenshot → menutup aplikasi**,
sehingga tidak ada state yang nyangkut antar-skenario. Viewport 390×844
(`deviceScaleFactor: 2`) memaksa Flutter merender layout mobile.

**Mengaktifkan FCM asli** (setelah konfigurasi Firebase tersedia):

```sh
dart pub global activate flutterfire_cli
flutterfire configure --project=<id-proyek-firebase>
```

`flutterfire` akan menulis `lib/firebase_options.dart` dan
`google-services.json`. Aplikasi otomatis beralih dari `DemoPushService` ke
`FcmPushService` tanpa mengubah UI.

---

## Daftar Screenshot

Seluruh screenshot diambil pada layout mobile **390 × 844**.

| # | Berkas | Isi |
|---|---|---|
| 1 | `01-login.png` | Halaman login (guard route: belum login selalu ke `/login`) |
| 2 | `02-login-validasi.png` | Validasi form: email tidak valid + sandi < 6 karakter |
| 3 | `03-beranda.png` | Beranda setelah login: kartu status, topik, simulator |
| 4 | `04-token.png` | Permission granted + token **terpotong** + `POST /devices` |
| 5 | `05-token-rotasi.png` | `onTokenRefresh` → kirim ulang token baru ke backend |
| 6 | `06-topik-aktif.png` | Topik `pengumuman-kampus` aktif (berlangganan) |
| 7 | `07-topik-nonaktif.png` | Log `subscribeToTopic` → `unsubscribeFromTopic` |
| 8 | `08-foreground-banner.png` | Banner in-app muncul saat foreground |
| 9 | `09-foreground-detail.png` | Klik banner → `/pengumuman/3` |
| 10 | `10-background-detail.png` | Klik banner background → `/pengumuman/2` |
| 11 | `11-terminated-detail.png` | `getInitialMessage()` → `/pengumuman/1` |
| 12 | `12-data-only.png` | Pesan hanya-data: **tanpa banner**, hanya log |
| 13 | `13-refresh-401.png` | `401 → refresh sekali → retry 200 OK` |
| 14 | `14-logout.png` | Setelah `Keluar`, guard mengembalikan ke `/login` |

---

## Checklist Verifikasi Mandiri

- [x] Token hanya di `flutter_secure_storage` — tidak di `SharedPreferences`,
      tidak di-hardcode, dan tidak pernah di-log/di-screenshot penuh.
- [x] 401 memicu refresh **sekali** lalu retry; refresh mati memaksa login ulang
      (ada test anti-loop).
- [x] Ketiga app state teruji dengan tabel bukti; klik masuk ke rute yang benar.
- [x] Pesan hanya-data tidak menampilkan banner otomatis (dibuktikan `12` +
      unit test `hasNotificationPayload`).
- [x] Topik untuk broadcast, token untuk pesan personal.
- [x] Background handler top-level dengan `@pragma('vm:entry-point')`.
- [x] `flutter analyze` bersih dan semua test lulus (**23 test**).
- [x] Hasil AI diverifikasi dan didokumentasikan pada folder `docs/`.

---

## Refleksi

### 1. Mengapa refresh token tidak boleh disimpan di `SharedPreferences`?

`SharedPreferences` menyimpan data dalam berkas XML **tanpa enkripsi**, mudah
dibaca lewat *rooted device*, *backup* (ADB/Google Backup), atau file explorer.
Refresh token adalah "tiket panjang" — bocor berarti penyerang bisa mempertahankan
akses selama token itu hidup, bahkan setelah pengguna mengganti sandi. Karena itu
refresh token hanya hidup di Keychain/Keystore (`flutter_secure_storage`) dan
dikirim lewat **body POST HTTPS**, bukan query URL yang tercatat di log server.

### 2. Apa yang rusak bila `onTokenRefresh` diabaikan satu semester?

FCM memutakhirkan registration token saat aplikasi di-reinstall, data dihapus,
perangkat dipulihkan, atau rotasi keamanan berkala terjadi. Tanpa listener ini,
backend tetap menyimpan **token basi** sehingga pengiriman notifikasi perlahan
menjadi sunyi tanpa error yang terlihat — mahasiswa berhenti menerima pengumuman
kampus tanpa sebab yang jelas. Karena itu listener wajib ada dan **mengirim ke
backend**, bukan sekadar mencetak ke log.

### 3. Kapan memakai topik, kapan memakai token perangkat?

Topik untuk **broadcast satu-per-satu banyak penerima** yang sama: "Kuliah
pengganti Jumat", "Libur nasional", pengumuman satu angkatan/UKM — backend cukup
sekali kirim ke topik. Token perangkat untuk **pesan personal** yang tidak boleh
dilihat orang lain: nilai akhir, tagihan UKT, presensi, atau pesan dari dosen
PA — karena topik bersifat publik bagi siapa pun yang Subscribe.

### 4. Bagian mana dari draf AI yang saya tolak/perbaiki?

Empat perbaikan utama: (a) **server tiruan 401** dipindah dari interceptor
bertumpuk ke `HttpClientAdapter` karena interceptor auth tidak menerima 401;
(b) **banner foreground** dibatasi hanya untuk payload ber-`notification`, agar
pesan hanya-data tidak ikut menampilkan banner; (c) **allow-list rute** ditambahkan
ke `routeFromMessage` agar payload pihak ketiga tidak bisa mengarahkan pengguna
sembarangan; (d) **API `flutter_local_notifications` v22** menuntut parameter
named (`settings:`, `id:`) sehingga draf awal tidak kompilasi. Detail dan
prompt lengkap di [`docs/ai_challenge.md`](docs/ai_challenge.md).

---

## Referensi

- [Modul Minggu 6 — Authentication, Security & FCM](https://jti-polinema.github.io/flutter-codelab/06-minggu-6-authentication-security-fcm/index.html)
- [FCM Flutter client (setup & token)](https://firebase.flutter.dev/docs/messaging/overview/)
- [FCM message types: notification vs data](https://firebase.google.com/docs/cloud-messaging/concept-options#notifications_and_data_messages)
- [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage)
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
- [GoRouter: redirect & deep linking](https://pub.dev/packages/go_router)
- [OWASP Mobile Top 10](https://owasp.org/www-project-mobile-top-10/)
