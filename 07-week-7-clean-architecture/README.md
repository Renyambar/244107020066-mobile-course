# Campus Notify — Clean Architecture (Minggu 7)

Aplikasi pengumuman kampus dengan autentikasi, keamanan token (rotating access/refresh),
dan simulasi push notification — dimigrasikan dari struktur Week 6 ke **Clean
Architecture feature-first** sesuai modul
[Minggu 7](https://jti-polinema.github.io/flutter-codelab/07-minggu-7-clean-architecture/index.html).

- Nama: Reny Ambarwati · NIM: 244107020066 · Kelas: TI-3F · Pemrograman Mobile
- App ID: `com.renyambar.campus_notify`

## Tujuan

1. Memisahkan aturan bisnis (`domain`) dari teknologi (`data`) dan UI (`presentation`).
2. Menjaga dependensi arsitektur tetap steril: `presentation` → `domain` ← `data`,
   dengan `domain` yang murni Dart (tanpa Flutter, dio, sqflite, maupun Firebase).
3. Mempertahankan perilaku aplikasi Week 6 secara identik setelah refactor.

## Arsitektur

```
presentation (UI + provider)  ──impor──▶  domain (entity, kontrak, use case)
data (model, data source,     ──impor──▶  domain (mengimplementasi kontrak)
      implementasi repository)
```

`domain/` tidak mengimpor satu pun paket eksternal — hanya `dart:async`/`dart:math`.

```
lib/
├── core/                     # failitas lintas fitur (Failure, format)
│   ├── failures.dart
│   └── format.dart
├── features/
│   ├── auth/
│   │   ├── domain/           # AuthUser, AuthRepository, RefreshSession, Login
│   │   ├── data/             # AuthModel, AuthApi, CampusApiClient, interceptor 401,
│   │   │                     # DemoCampusServer, SessionStore, AuthRepositoryImpl
│   │   └── presentation/     # AuthController, LoginPage
│   ├── announcements/
│   │   ├── domain/           # Announcement, AnnouncementRepository, GetAnnouncement
│   │   ├── data/             # AnnouncementModel, MockAnnouncementSource, AnnouncementRepositoryImpl
│   │   └── presentation/     # AnnouncementController, AnnouncementPage
│   └── notifications/
│       ├── domain/           # PushMessage, PushGateway, DeviceRegistry, RegisterDevice
│       ├── data/             # DemoPushGateway, MockDeviceRegistry, PushBootstrap
│       └── presentation/     # PushSimulator (banner + dialog + tap → detail)
├── app/
│   ├── router.dart           # go_router
│   ├── campus_app.dart
│   └── presentation/home_page.dart
└── main.dart                 # bootstrap + dukungan ?semantics=true
```

### Pola hasil

- `core/failures.dart`: `typedef Result<T> = ({T? value, Failure? failure})` dengan
  `success(value)` / `failure(f)`; `sealed class Failure`
  (Local/Network/Validation/Auth) — tanpa exception di alur utama.
- Entity memakai record + `copyWith` ala modul; konversi JSON hanya di `data/`.
- Use case hanya untuk operasi ber-aturan: `Login` (validasi + normalisasi + kontrak dua
  token), `GetAnnouncement` (validasi id), `RegisterDevice` (validasi token); serta
  `RefreshSession` yang dipakai interceptor 401.

## Fitur

- Login (validasi form, NIM dinormalisasi, pesan gagal) dan logout.
- Sesi aman: token rotating, auto-refresh saat 401, hapus sesi saat refresh gagal.
- Daftar & detail pengumuman (mock server offline).
- Push notification via kontrak `PushGateway` (aktif: `DemoPushGateway`, siap FCM —
  lihat [`docs/fcm_integration.md`](docs/fcm_integration.md)).
- Tema krem–cokelat, layout mobile.

## Menjalankan

```bash
flutter pub get        # ambil dependensi
flutter analyze        # pastikan "No issues found!"
flutter test           # unit test use case dengan repository palsu
flutter run -d chrome  # jalankan aplikasi
```

Aplikasi berjalan offline penuh (server kampus & push disimulasikan di dalam kode).
Akun demo: NIM apa pun (10 digit) + password apa pun kecuali `salah`.

### Membangun & menyajikan versi web

```bash
flutter build web --release
node tool/serve.mjs                 # menyajikan build/web di http://localhost:8080
```

### Menangkap screenshot (seperti pada folder `screenshots/`)

```bash
node tool/serve.mjs                                # terminal 1
node tool/capture.mjs login screenshots/after_login.png   # terminal 2
```

Skenario yang tersedia: `login`, `login-gagal`, `beranda`, `push-foreground`,
`push-detail`, `token-rotasi`, `refresh-401`, `logout`. Tambahkan
`?semantics=true` pada URL bila ingin pohon semantik (aksesibilitas) ikut tampil.

## Hasil verifikasi

| Pemeriksaan | Perintah | Hasil |
| --- | --- | --- |
| Analisis statis | `flutter analyze` | No issues found! |
| Unit test | `flutter test` | 16 test lulus |
| Grep 1: `presentation/` bebas `FlutterSecureStorage` / `jsonDecode` / `SharedPreferences` / `openDatabase` / `getDatabasesPath` / `Dio(` | PowerShell `Select-String` | 0 temuan |
| Grep 2: `domain/` & `core/` bebas `package:flutter/`, `package:dio/`, `package:sqflite/`, `package:firebase_` | PowerShell `Select-String` | 0 temuan |
| Grep 3 (ekstra): `domain/` & `core/` bebas seluruh `import 'package:` | PowerShell `Select-String` | 0 temuan |
| Build web | `flutter build web --release` | Sukses |

Test memakai repository palsu (fake) — tanpa HTTP maupun penyimpanan nyata — pada
`test/features/`: `login_usecase_test.dart`, `get_announcement_test.dart`,
`register_device_test.dart`, plus `test/core/format_test.dart`.

## Before vs After

Kedua versi dijalankan lewat web dengan viewport mobile 390×844 dan dibandingkan
skenario per skenario: hasil **identik**.

| Skenario | Week 6 (before) | Week 7 (after) |
| --- | --- | --- |
| Login valid | `before_login.png` | `after_login.png` |
| Login gagal | `before_login_validasi.png` | `after_login_validasi.png` |
| Validasi form + beranda | `before_beranda.png` | `after_beranda.png` |
| Pesan push foreground | `before_foreground.png` | `after_foreground.png` |
| Detail pengumuman | `before_foreground_detail.png` | `after_foreground_detail.png` |
| Rotasi token | `before_token_rotasi.png` | `after_token_rotasi.png` |
| Refresh 401 | `before_refresh_401.png` | `after_refresh_401.png` |
| Logout | `before_logout.png` | `after_logout.png` |

Citra tersimpan di [`screenshots/`](screenshots). Screenshot FCM dengan Firebase
sungguhan ditambahkan sendiri setelah mengikuti
[`docs/fcm_integration.md`](docs/fcm_integration.md).

## Dokumentasi

- [`docs/ai_challenge.md`](docs/ai_challenge.md) — tantangan refactor, pemetaan file
  lama → baru, keputusan desain & trade-off, hasil grep.
- [`docs/fcm_integration.md`](docs/fcm_integration.md) — langkah mengaktifkan FCM
  (menambah dependensi, `FcmPushGateway`, menukar pabrik `createPushGateway()`).

## Referensi

- Modul: <https://jti-polinema.github.io/flutter-codelab/07-minggu-7-clean-architecture/index.html>
- Kode dasar: folder [`../06-week-6-authentication-security-fcm`](../06-week-6-authentication-security-fcm)
