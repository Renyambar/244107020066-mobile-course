# Minggu 3: Navigation & State Management

Dokumentasi dan laporan tugas praktikum Minggu 3 mata kuliah Pemrograman Mobile.

## Identitas Mahasiswa

- **Nama:** Reny Ambarwati
- **NIM:** 244107020049
- **Kelas:** TI-3F
- **Mata Kuliah:** Pemrograman Mobile

---

## Praktikum 1: Navigasi dan GoRouter

### Deskripsi Implementasi

Pada praktikum pertama, saya mempelajari dasar navigasi di Flutter serta beralih dari mekanisme imperatif bawaan (Navigator 1.0) ke routing deklaratif menggunakan package `go_router`:

- **Kelemahan Navigator 1.0**: Penggunaan `Navigator.push` dan `MaterialPageRoute` membuat alur navigasi sulit diatur saat aplikasi membesar, rawan terjadi duplikasi logika perpindahan, tidak mendukung deep linking bawaan web/mobile secara bersih, serta penanganan rute terlindungi (guard/redirect) tersebar di banyak tempat.
- **Konfigurasi `GoRouter`**: Didefinisikan secara terpusat dengan `MaterialApp.router` dan parameter `routerConfig`. Menggunakan rute utama `/` (`HomePage`) dan sub-rute berparameter `detail/:id` (`DetailPage`).
- **Path Parameter**: Nilai parameter URL dinamis diakses secara aman lewat `state.pathParameters['id']!`.
- **Perpindahan Halaman**: Menggunakan `context.go('/detail/${index + 1}')` untuk berpindah ke rute detail. Tombol back sistem otomatis mengenali hierarki tumpukan rute.

### Tangkapan Layar

| Halaman Utama (Home List) | Halaman Detail dengan Path Parameter |
| :---: | :---: |
| ![Praktikum 1 Home](screenshots/praktikum1_home.png) | ![Praktikum 1 Detail](screenshots/praktikum1_detail.png) |

---

## Praktikum 2: State Management dengan Riverpod

### Deskripsi Implementasi

Pada praktikum kedua, saya mengimplementasikan pengelolaan state global aplikasi ToDo menggunakan package `flutter_riverpod`:

- **Mengapa State Management Diperlukan**: Mengandalkan `setState` hanya efektif untuk state lokal dalam satu widget. Ketika state harus dibagikan antar berbagai halaman atau bertahan saat widget di-unmount, mengangkat state ke parent teratas (lifting state up) menyebabkan masalah *prop drilling* yang rumit. Riverpod memindahkan state keluar dari widget tree sehingga logika mudah diuji, compile-safe, dan konsisten terhadap konsep UI deklaratif ($UI = f(state)$).
- **`ProviderScope`**: Membungkus root widget aplikasi (`runApp(const ProviderScope(child: MyApp()))`) sebagai kontainer global penyimpan seluruh state provider.
- **Model `Todo` & Immutability**: State daftar tugas dimodelkan dalam objek `Todo` dengan method `copyWith`. State tidak pernah diubah secara langsung (`state.add(...)` dilarang). Notifier selalu mengembalikan list baru menggunakan *spread operator* (`state = [...state, newTodo]`) agar Riverpod mendeteksi perubahan referensi memori dan memicu rebuild UI.
- **`TodoListNotifier` & `NotifierProvider`**: Mewarisi kelas `Notifier<List<Todo>>` yang memuat logika manipulasi data (`add`, `toggle`, `remove`).
- **`ConsumerWidget`**: Widget membaca state menggunakan `ref.watch(todoListProvider)` di dalam method `build()`, dan memanggil method mutasi menggunakan `ref.read(todoListProvider.notifier)` di dalam event callback.

### Tangkapan Layar

| Kondisi Kosong (Empty State) | Dialog Tambah Tugas Baru | Daftar Tugas Terisi & Ceklis |
| :---: | :---: | :---: |
| ![Praktikum 2 Empty](screenshots/praktikum2_empty.png) | ![Praktikum 2 Dialog](screenshots/praktikum2_add_dialog.png) | ![Praktikum 2 List](screenshots/praktikum2_list.png) |

---

## Praktikum 3: AsyncValue (Loading, Error, Success)

### Deskripsi Implementasi

Pada praktikum ketiga, saya menerapkan penanganan state asinkron untuk operasi I/O (seperti request API atau pembacaan database) menggunakan fitur `AsyncValue` dari Riverpod:

- **Masalah Pendekatan Manual Tiga Boolean**: Mengelola status asinkron dengan variabel manual (`isLoading`, `hasError`, `data`) rawan bug inkonsistensi (misal `isLoading == true` bersamaan dengan `hasError == true`).
- **`AsyncNotifier` & `AsyncValue<T>`**: Riverpod memodelkan ketiga kemungkinan tersebut dalam satu tipe data terpadu: `AsyncLoading`, `AsyncError`, dan `AsyncData`.
- **`AsyncValue.guard`**: Menghindari blok try/catch manual yang tersebar dengan otomatis menangkap exception dan membungkusnya ke dalam `AsyncError`.
- **Pola `.when()` pada UI**: Memastikan semua kondisi tertangani dengan rapi:
  - `loading`: Menampilkan `CircularProgressIndicator` dan pesan progres.
  - `error`: Menampilkan ikon peringatan, pesan kegagalan, dan tombol *Coba lagi* yang mengeksekusi `ref.invalidate(provider)`.
  - `data`: Menampilkan data produk/statistik yang telah berhasil diambil.

### Tangkapan Layar

| State Loading (Spinner) | State Error & Tombol Retry | State Success (Data Berhasil) |
| :---: | :---: | :---: |
| ![Praktikum 3 Loading](screenshots/praktikum3_loading.png) | ![Praktikum 3 Error](screenshots/praktikum3_error.png) | ![Praktikum 3 Success](screenshots/praktikum3_success.png) |

---

## Tugas Utama: Aplikasi ToDo & Statistik Lengkap

### Deskripsi Implementasi

Aplikasi ToDo dikembangkan secara komprehensif dengan menyatukan seluruh materi navigasi GoRouter, state management Riverpod, serta visualisasi asinkron AsyncValue:

1. **Struktur Multi-page dengan GoRouter**:
   - `/`: Halaman utama daftar tugas (`TodoPage`).
   - `/stats`: Halaman statistik akademik terpisah (`StatsPage`).
   - `/detail/:id`: Halaman rincian tugas mandiri (`DetailPage`) yang membaca parameter ID dinamis dan mendukung navigasi kembali secara deklaratif.
2. **Navigasi Tab Terpadu (`ScaffoldWithNavBar`)**: Menggunakan `ShellRoute` dari GoRouter yang membungkus `NavigationBar` Material 3 sehingga bar navigasi tetap konsisten saat beralih antara menu Tugas dan Statistik.
3. **Penyaringan Tugas Reaktif**: Pengguna dapat menyaring tugas berdasarkan status: *Semua*, *Aktif* (belum selesai), dan *Selesai* menggunakan `SegmentedButton`.
4. **Header Ringkasan Kemajuan**: Menampilkan total tugas, jumlah tugas tuntas, serta persentase capaian progres mingguan secara otomatis.
5. **Halaman Statistik Cerdas**: Mengambil snapshot nyata dari `todoListProvider` untuk menghitung rasio penyelesaian tugas dengan simulasi latensi jaringan dan penanganan error interaktif.

### Tangkapan Layar

| Halaman Utama Tugas | Filter Tugas Aktif | Rincian Tugas (Detail Page) |
| :---: | :---: | :---: |
| ![Tugas Utama Todos](screenshots/tugas_utama_todos.png) | ![Tugas Utama Filter](screenshots/tugas_utama_filter.png) | ![Tugas Utama Detail](screenshots/tugas_utama_detail.png) |

| Statistik: Loading | Statistik: Sukses (Data Riil) | Statistik: Error & Retry |
| :---: | :---: | :---: |
| ![Stats Loading](screenshots/tugas_utama_stats_loading.png) | ![Stats Success](screenshots/tugas_utama_stats_success.png) | ![Stats Error](screenshots/tugas_utama_stats_error.png) |

---

## Refactoring Challenge

### Perubahan yang Dilakukan

1. **Pemisahan Widget Reusable `TodoTile`**:
   - Item baris tugas diekstrak ke dalam widget mandiri `lib/widgets/todo_tile.dart`.
   - Menerima parameter `todo`, callback `onToggle`, `onDelete`, dan `onTap`.
   - Mengurangi kompleksitas kode pada method `build()` di `TodoPage` sehingga lebih modular, bersih, dan mudah diuji.
2. **Ekstraksi Provider Turunan (`filteredTodoListProvider`)**:
   - Logika filter tugas dipisahkan dari lapisan UI ke dalam provider turunan (`Provider<List<Todo>>`) pada `lib/providers/todo_provider.dart`.
   - Provider ini membaca `todoListProvider` dan `todoFilterProvider`, kemudian menghasilkan sublist yang relevan secara komputasi murni.
3. **Integrasi Navigasi GoRouter dengan `NavigationBar`**:
   - Menerapkan `ShellRoute` pada `lib/router/app_router.dart` dengan wrapper `ScaffoldWithNavBar`.
   - Tab navigasi bawah mengontrol rute `/` dan `/stats` secara terpusat tanpa reload state yang tidak perlu.
4. **Kerapian Kode & Standar Linter (`flutter analyze`)**:
   - Dilakukan verifikasi statis kode, menghasilkan **0 issues / warnings**.

![Hasil flutter analyze](screenshots/flutter_analyze.png)

---

## Testing

### Pengujian Kode yang Diterapkan

Sesuai instruksi dan panduan codelab Minggu 3, pengujian difokuskan pada dua aspek utama:

1. **Unit Test Notifier (`test/unit_test.dart`)**:
   - Sesuai requirement AI Challenge: *"Berikan unit test untuk notifier-nya"*.
   - Menguji `StatsNotifier` secara terisolasi menggunakan `ProviderContainer`.
   - Memverifikasi keberhasilan emisi data statistik (`AsyncData`) dengan minimal 3 metrik kalkulasi.
   - Memverifikasi penangkapan kesalahan (`AsyncError`) saat terjadi kegagalan jaringan simulasi.
2. **Widget Test Reaktivitas UI (`test/widget_test.dart`)**:
   - Sesuai requirement bagian Testing codelab: *"Widget test untuk memastikan UI bereaksi terhadap perubahan state provider"*.
   - Menguji penambahan tugas baru melalui dialog (`menambah tugas baru`), memastikan form input merespons event tap dan tugas baru langsung ter-render pada daftar tugas.

Hasil eksekusi `flutter test` menunjukkan seluruh test lulus dengan sempurna (**All tests passed!**):

![Hasil flutter test](screenshots/flutter_test.png)

---

## Checklist Verifikasi

- [x] Navigasi GoRouter bekerja: pindah halaman, back, dan akses path detail langsung.
- [x] ProviderScope membungkus root aplikasi; state ToDo bertahan saat berpindah halaman.
- [x] UI AsyncValue menangani loading, error, dan success, bukan hanya success.
- [x] `flutter analyze` tanpa issue (0 warnings) dan semua test lulus.
- [x] Hasil AI diverifikasi dan didokumentasikan pada folder `docs/ai_challenge.md`.

---

## AI Prompt Challenge

Dokumentasi lengkap disimpan pada berkas [docs/ai_challenge.md](docs/ai_challenge.md).

### Prompt yang Diajukan

```text
Buatkan halaman Flutter bernama StatsPage menggunakan flutter_riverpod.
Requirements:
- ConsumerWidget dengan satu AsyncNotifierProvider yang mensimulasikan
  pengambilan data statistik (delay 2 detik, kadang gagal 30%).
- UI harus menangani loading (spinner), error (pesan + tombol retry),
  dan success (ListView 3 item).
- Berikan unit test untuk notifier-nya.
Jelaskan setiap bagian kode dalam komentar.
```

### AI Verification Checklist

| No | Poin Pemeriksaan | Hasil Evaluasi | Analisis & Tindakan Perbaikan |
|:---:|:---|:---:|:---|
| 1 | State diubah secara immutable | **Lolos** | AI tidak melakukan `state.add()`. Namun data awal bersifat statis sehingga diperbaiki dengan menyinkronkannya ke `todoListProvider`. |
| 2 | `ref.watch` hanya di `build`, `ref.read` di callback | **Lolos** | Penempatan `ref.watch` dan `ref.read` sudah mematuhi kaidah Riverpod. |
| 3 | Ketiga state `AsyncValue` ditangani | **Lolos** | Menangani `loading`, `error`, dan `data` secara menyeluruh melalui `.when()`. |
| 4 | Provider dideklarasikan dengan tipe eksplisit | **Lolos** | Deklarasi menggunakan generics lengkap `AsyncNotifierProvider<StatsNotifier, List<StatItem>>`. |
| 5 | Menggunakan API Riverpod modern | **Diperbaiki** | AI menggunakan `ref.refresh()` usang; diganti dengan `ref.invalidate()` dan method `refresh()` berbasis `AsyncValue.guard`. |
| 6 | Lolos `flutter analyze` & `flutter test` | **Diperbaiki** | Memperbaiki mock flag `forceErrorMode` agar pengujian unit test dan demo UI deterministik dan tidak *flaky*. |

---

## Refleksi

### 1. Kapan setState masih cukup, dan kapan state harus naik ke Riverpod?

`setState` masih sangat tepat dan efisien digunakan untuk **state lokal yang bersifat internal (ephemeral state)** pada satu widget dan tidak memengaruhi bagian lain aplikasi. Contohnya: status membuka/menutup dialog lokal, animasi transisi internal, teks sementara pada `TextEditingController`, atau status expand/collapse accordion. 

Sebaliknya, state wajib dinaikkan ke **Riverpod (app-level state)** ketika:
- State perlu diakses atau dimanipulasi oleh lebih dari satu halaman/widget yang berjauhan pada widget tree (misalnya daftar tugas ToDo yang ditampilkan di halaman utama dan dihitung di halaman statistik).
- State harus tetap bertahan di memori meskipun halaman atau widget yang bersangkutan telah di-pop atau di-unmount.
- Logika bisnis perlu diuji secara mandiri melalui *unit test* tanpa harus me-render widget tree Flutter.

### 2. Apa perbedaan context.go dan context.push, dan kapan masing-masing tepat digunakan?

- **`context.go(path)`**: Bekerja secara deklaratif dengan mencocokkan URI tujuan terhadap konfigurasi router dan **menggantikan tumpukan rute (route stack)** sesuai hierarki path yang didefinisikan. Sangat tepat digunakan untuk navigasi tingkat atas (top-level), redirect autentikasi/login, deep link langsung, dan pergantian tab menu utama pada `NavigationBar`.
- **`context.push(path)`**: Bekerja dengan **menumpuk (*push*) rute baru di atas stack navigasi saat ini**, mirip seperti `Navigator.push`. Pengguna dapat kembali ke halaman sebelumnya dengan menekan tombol kembali (*back*). Sangat tepat digunakan untuk alur detail atau form bertingkat (misalnya membuka rute `/detail/:id` dari daftar tugas).

### 3. Bagaimana AsyncValue mencegah bug dibanding tiga boolean terpisah?

Jika menggunakan tiga variabel boolean terpisah (`isLoading`, `hasError`, `data`), pengembang harus memperbarui status ketiga variabel tersebut secara manual di setiap tahap proses asinkron. Hal ini sangat rawan *human error*, misalnya:
- Lupa mereset `isLoading = false` ketika terjadi exception di blok catch.
- Keadaan tidak valid di mana `isLoading == true` bersamaan dengan `hasError == true`, sehingga UI menampilkan indikator loading dan pesan error sekaligus.
- Terjadinya layar putih kosong (*blank screen*) karena kondisi error tidak memiliki penanganan UI yang eksplisit.

`AsyncValue<T>` memodelkan status asinkron sebagai sebuah *discriminated union* (hanya bisa berada di salah satu status: `AsyncLoading`, `AsyncError`, atau `AsyncData`). Melalui metode `.when()`, Dart memaksa *exhaustive checking* di level kompilasi sehingga seluruh kemungkinan status wajib ditangani, menghilangkan kemungkinan inkonsistensi status secara absolut.

### 4. Bagian mana dari hasil AI yang Anda perbaiki, dan mengapa?

1. **Sinkronisasi Data Riil**: Kode awal dari AI menghasilkan data statistik dummy yang *hardcoded*. Saya memperbaikinya dengan menghubungkan `StatsNotifier` langsung ke `todoListProvider` menggunakan `ref.read(todoListProvider)` sehingga metrik total tugas, tugas selesai, dan tugas aktif merefleksikan data nyata aplikasi.
2. **Penggantian API Usang (`ref.refresh` $\to$ `ref.invalidate`)**: AI merekomendasikan `ref.refresh()`. Saya memperbaikinya dengan `ref.invalidate(statsProvider)` yang merupakan standar terkini di Riverpod 2.x/3.x, serta menambahkan metode `refresh()` eksplisit dengan pembungkus `AsyncValue.guard`.
3. **Kontrol Deterministik untuk Pengujian & Demo**: AI menggunakan kegagalan acak murni (`Random().nextInt(100) < 30`) yang menyebabkan unit test bersifat *flaky* (kadang lulus kadang gagal secara tidak terduga). Saya menambahkan properti static `forceErrorMode` sehingga pengujian unit test dan demo antarmuka dapat memicu status error secara pasti.
4. **Penyempurnaan Visual Material 3**: Tampilan awal AI hanya berupa `ListTile` biasa. Saya memperkayanya menjadi `Card` Material 3 dengan warna tematik, ikon indikator, dan semantik aksesibilitas.