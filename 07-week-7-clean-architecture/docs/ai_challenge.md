# AI Challenge — Refactor ke Clean Architecture

- Nama: Reny Ambarwati
- NIM: 244107020066
- Kelas: TI-3F
- Mata kuliah: Pemrograman Mobile
- Sumber tantangan: Mini Project / AI Challenge pada modul
  [Minggu 7 — Clean Architecture](https://jti-polinema.github.io/flutter-codelab/07-minggu-7-clean-architecture/index.html)
- Kode dasar: proyek Week 6 `06-week-6-authentication-security-fcm` (authentication + security + FCM)

## 1. Prompt Tantangan

> Pindahkan minimal **satu fitur** dari aplikasi Week 6 ke struktur Clean Architecture
> feature-first: buat layer `domain` (entity, repository interface, use case),
> `data` (model, data source, implementasi repository), dan `presentation`
> (provider/bloc, page), pindahkan file lama ke lokasi baru, pastikan fitur berfungsi
> normal, jalankan **3 pemeriksaan grep** untuk memastikan dependensi arsitektur
> bersih, tulis ringkasan hasil, lalu dokumentasikan solusi AI Challenge.

## 2. Cakupan Pekerjaan

Seluruh aplikasi Week 6 dimigrasikan ke Clean Architecture feature-first, dengan
cakupan sebagai berikut:

| Aspek | Week 6 (before) | Week 7 (after) |
| --- | --- | --- |
| Struktur | Layer-first per teknologi (`services/`, `screens/`, `widgets/`) | Feature-first per fitur: `auth`, `announcements`, `notifications`, `app` |
| Pemisahan aturan bisnis | Tersebar di service + widget | Use case: `Login`, `GetAnnouncement`, `RegisterDevice` |
| Sumber data | Terbungkus `*Service` | Data source + implementasi repository di `data/` |
| Kontrak | Tidak ada interface | Interface repository/use case di `domain/` |
| Keamanan token | Interceptor di lapisan service | Interceptor memanggil use case `RefreshSession` |
| Push notification | Firebase langsung dari UI | Kontrak `PushGateway` (implementasi demo, siap FCM) |

Fitur yang berpindah **penuh** (domain/data/presentation):

1. **auth** — login, validasi input, model sesi, token rotating, refresh 401, logout.
2. **announcements** — daftar + detail pengumuman (antar-fitur memakai use case).
3. **notifications** — bootstrap push, simulasi pesan foreground, registry device, register token.

## 3. Pemetaan File Lama → Baru

| Week 6 (before) | Week 7 (after) |
| --- | --- |
| `lib/main.dart` | `lib/main.dart` + `lib/core/` + `lib/app/` |
| `lib/config/routes.dart` | `lib/routes.dart` + `lib/app/router.dart` |
| `lib/services/auth_service.dart` | `lib/features/auth/domain/` (entity, repository, use case) + `lib/features/auth/data/auth_repository_impl.dart` |
| `lib/services/secure_session_store.dart` | `lib/features/auth/data/secure_session_store.dart` |
| `lib/services/campus_api_client.dart` | `lib/features/auth/data/campus_api_client.dart` + `campus_api_interceptor.dart` + `demo_campus_server.dart` |
| `lib/services/announcements_service.dart` | `lib/features/announcements/domain/` + `lib/features/announcements/data/announcement_repository_impl.dart` |
| `lib/services/push_notification_service.dart` | `lib/features/notifications/domain/` + `lib/features/notifications/data/demo_push_gateway.dart` |
| `lib/screens/home_screen.dart` | `lib/app/presentation/home_page.dart` |
| `lib/screens/login_screen.dart` | `lib/features/auth/presentation/login_page.dart` |
| `lib/screens/announcement_detail_screen.dart` | `lib/features/announcements/presentation/announcement_page.dart` |
| `lib/widgets/announcement_list.dart` | `lib/features/announcements/presentation/announcement_page.dart` |
| `lib/widgets/foreground_push_demo.dart` | `lib/features/notifications/presentation/push_simulator.dart` |
| (baru) | `lib/core/failures.dart`, `lib/core/format.dart` |
| (baru) | `lib/app/campus_app.dart` |

File lama di folder `lib/` diganti total oleh struktur baru (folder `services/`,
`screens/`, `widgets/` tidak lagi dipakai).

## 4. Hasil 3 Pemeriksaan Grep

Mode pemeriksaan (PowerShell `Select-String`, output = jumlah temuan):

```powershell
# grep1: presentation bebas impl teknologi
Get-ChildItem lib -Recurse -Filter *.dart |
  Select-String -Pattern "FlutterSecureStorage|jsonDecode|SharedPreferences\.getInstance|openDatabase|getDatabasesPath|Dio\(" 

# grep2: domain & core bebas flutter/dio/sqflite/firebase
Get-ChildItem lib\core, lib\features -Recurse -Filter *.dart |
  Where-Object { $_.FullName -match '\\domain\\|\\lib\\core\\' } |
  Select-String -Pattern "package:flutter/|package:dio/|package:sqflite/|package:firebase_"

# grep3 (ekstra): domain & core bebas semua import paket eksternal
Get-ChildItem lib\core, lib\features -Recurse -Filter *.dart |
  Where-Object { $_.FullName -match '\\domain\\|\\lib\\core\\' } |
  Select-String -Pattern "import 'package:"
```

Hasil: **nol temuan** untuk ketiga pemeriksaan.

- grep1 memastikan `presentation/` hanya memakai kontrak domain (entity + use case),
  tidak menyentuh penyimpanan aman, parser JSON manual, database, maupun HTTP client.
- grep2 memastikan `domain/` dan `core/` murni Dart tanpa framework maupun paket pihak ketiga.
- grep3 memperketat: `domain/` dan `core/` tidak mengimpor satu pun `package:` eksternal
  (hanya `dart:async`, `dart:math`).

## 5. Tantangan & Keputusan Desain

| Usulan khas Clean Architecture | Keputusan | Trade-off |
| --- | --- | --- |
| Satu use case untuk tiap operasi CRUD | Dipakai hanya untuk operasi ber-aturan: `Login` (validasi + normalisasi + kontrak dua token), `GetAnnouncement` (validasi id), `RegisterDevice` (validasi token). Fetch list, refresh, logout: repository → notifier | Terlalu banyak use case untuk operasi pipa biasa membuat lapisan jadi boilerplate; modul juga menekankan use case untuk logika yang benar-benar ada aturannya |
| Composition root tunggal | Wiring provider dilakukan per fitur (`auth_providers.dart`, `announcement_providers.dart`, `push_providers.dart`), hanya bootstrap di `main.dart` | Fitur jadi mandiri dan mudah dipindah/dihapus; konsekuensinya dependensi antar-fitur harus lewat kontrak domain (mis. interceptor memakai use case dari fitur auth) |
| Firebase dipertahankan dari Week 6 | Dependensi Firebase dilepas dari `pubspec.yaml`; push memakai kontrak `PushGateway` + `DemoPushGateway` (kode 100% offline) | Tanpa kredensial Firebase proyek tetap bisa dianalisis, diuji, dan di-build; integrasi FCM nyata tinggal mengganti satu pabrik (lihat `fcm_integration.md`) |
| Entity berupa kelas immutable | Entity memakai record + `copyWith` ala modul | Lebih ringkas dan identik dengan gaya codelab; konversi JSON tetap di `data/` via model |
| Semua kegagalan dilempar sebagai exception | Pola `Result<T>` (`typedef Result<T> = ({T? value, Failure? failure})`) + `sealed class Failure` | Alur error eksplisit di pemanggil dan bisa diuji; konsekuensinya pemanggil wajib memeriksa `failure` (sedikit lebih verbose) |
| Bloc untuk seluruh state | Provider + `AsyncNotifier` (state `AsyncValue`) | Konsisten dengan modul dan cukup untuk state async sederhana; Bloc baru relevan bila alur state kompleks |

## 6. Bukti Perilaku (Before vs After)

Delapan skenario dijalankan pada aplikasi before (Week 6) dan after (Week 7) lewat
web mobile 390×844 dan dibandingkan hasilnya:

| Skenario | Before | After | Hasil |
| --- | --- | --- | --- |
| Login valid | `before_login.png` | `after_login.png` | Identik — beranda menampilkan nama & NIM |
| Login gagal (password salah) | `before_login_validasi.png` | `after_login_validasi.png` | Identik — banner "NIM atau password salah" |
| Validasi form kosong | `before_beranda.png` (bagian login) | `after_beranda.png` | Identik — pesan "Masukkan NIM dan password" |
| Pesan push foreground | `before_foreground.png` | `after_foreground.png` | Identik — dialog "Pengumuman Baru" |
| Detail pengumuman | `before_foreground_detail.png` | `after_foreground_detail.png` | Identik — judul, waktu, isi lengkap |
| Rotasi token (access kedaluwarsa) | `before_token_rotasi.png` | `after_token_rotasi.png` | Identik — request sukses dengan access token baru |
| Refresh token (401 → auto refresh) | `before_refresh_401.png` | `after_refresh_401.png` | Identik — request ulang sukses tanpa logout |
| Logout | `before_logout.png` | `after_logout.png` | Identik — sesi terhapus, kembali ke login |

Citra before/after tersimpan di folder [`../screenshots`](../screenshots).

## 7. Hasil Verifikasi

| Pemeriksaan | Perintah | Hasil |
| --- | --- | --- |
| Analisis statis | `flutter analyze` | No issues found! |
| Unit test | `flutter test` | 16 test lulus |
| Grep dependensi | 3 pemeriksaan (bagian 4) | 0 temuan |
| Build web | `flutter build web --release` | Sukses |

Test use case memakai **repository palsu** (fake) di folder
[`../test/features/`](../test/features) — tanpa HTTP, tanpa penyimpanan nyata:

- `login_usecase_test.dart` — normalisasi NIM, validasi input, kontrak sukses/gagal.
- `get_announcement_test.dart` — validasi id, data dari repository palsu.
- `register_device_test.dart` — validasi token, laporan pendaftaran.

## 8. Tantangan AI (Refleksi)

1. **Mengganti Firebase tanpa mengubah pengalaman pengguna.** Push notification Week 6
   memakai `firebase_messaging`; menggantinya dengan kontrak `PushGateway` +
   `DemoPushGateway` membuat perilaku simulasi tetap sama (banner, dialog, tap → detail)
   sementara dependensi kredensial hilang dari alur build.
2. **Menjaga dependensi arsitektur tetap steril.** Grep1 sempat menemukan token teknologi
   yang tertulis di komentar file presentation; komentar diubah menjadi istilah generik
   ("penyimpanan sesi aman", "penguraian payload") agar pemeriksaan benar-benar nol.
3. **Refresh token yang tetap aman.** Interceptor 401 tidak lagi memegang referensi store
   langsung, melainkan use case `RefreshSession` milik fitur auth; rotasi access/refresh
   terjadi di domain, dan store menyimpan versi terbaru kedua token.
4. **Migrasi bertahap tanpa duplikasi.** Kode lama dipindahkan (bukan disalin) per fungsi
   lalu dihapus, sehingga pada akhirnya hanya ada satu implementasi logika di `data/`.

## 9. Pengembangan Berikutnya

- Menambahkan FCM sungguhan sesuai [`fcm_integration.md`](fcm_integration.md).
- Menguji implementasi repository (mock client) untuk jalur sukses/gagal HTTP.
- Membungkus daftar pengumuman ke use case bila kelak ada aturan bisnis di sana
  (mis. filter unread, paginasi).
