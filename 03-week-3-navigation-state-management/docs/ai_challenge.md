# AI Challenge & Verification Documentation

Dokumentasi penggunaan AI Coding Assistant pada Praktikum Minggu 3: Navigation & State Management.

---

## 1. Prompt yang Digunakan

Prompt berikut diajukan kepada AI coding assistant untuk membuat implementasi dasar halaman statistik:

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

---

## 2. Output Awal AI (Analisis & Evaluasi)

AI menghasilkan kode awal dengan pola:
1. `StateNotifierProvider` atau generator dasar dengan model data statistik terpisah.
2. Penanganan `AsyncValue.when` untuk loading, error, dan data.
3. Simulasi delay dan error menggunakan `Future.delayed` dan `Random().nextDouble() < 0.3`.
4. Unit test dasar menggunakan `ProviderContainer`.

### Temuan Evaluasi Awal:
- **Ketergantungan Data**: Data statistik awal yang dihasilkan AI bersifat statis/dummy dan tidak tersinkronisasi dengan daftar tugas aktual pada `todoListProvider`.
- **API Riverpod Usang**: Menggunakan rekomendasi `ref.refresh()` alih-alih `ref.invalidate()` atau metode berbasis `AsyncValue.guard`.
- **Pengujian Flaky (Tidak Deterministik)**: Simulasi kegagalan acak murni pada pengujian menyebabkan hasil `flutter test` terkadang lolos dan terkadang gagal.
- **Tampilan UI**: UI hasil AI hanya menggunakan `ListTile` sederhana tanpa styling Material 3 yang memadai.

---

## 3. Tindakan Perbaikan yang Dilakukan

Berdasarkan temuan di atas, berikut adalah perbaikan dan penyempurnaan teknis yang diterapkan:

| Poin Verifikasi | Status | Tindakan & Perbaikan Teknis |
| :--- | :---: | :--- |
| **Immutability State** | Lolos | Seluruh mutasi state pada Notifier menggunakan pembuatan list baru (`[...state, item]`), tidak menggunakan mutasi langsung (`state.add()`). |
| **Penggunaan `ref.watch` vs `ref.read`** | Lolos | `ref.watch` diterapkan secara ketat hanya di dalam metode `build()` widget untuk reaktivitas. `ref.read` digunakan secara eksklusif di dalam event callback. |
| **Penanganan Ketiga State `AsyncValue`** | Lolos | Menggunakan pattern matching `.when()` yang menangani secara lengkap state `loading`, `error`, dan `data (success)`. |
| **Deklarasi Tipe Eksplisit** | Lolos | Provider dideklarasikan dengan tipe eksplisit `AsyncNotifierProvider<StatsNotifier, List<StatItem>>`. |
| **Modernisasi API Riverpod** | Diperbaiki | Mengganti `ref.refresh()` usang dengan `ref.invalidate()`, serta melengkapi class `StatsNotifier` dengan method `refresh()` yang menggunakan `AsyncValue.guard`. |
| **Sinkronisasi Data Riil** | Diperbaiki | Mengintegrasikan pembacaan data statistik dari `todoListProvider` melalui `ref.read(todoListProvider)` agar nilai metrik (Total, Selesai, Tertunda) merefleksikan state aplikasi secara langsung. |
| **Deterministik untuk Unit Testing** | Diperbaiki | Menambahkan konfigurasi `simulationDelay` dan `globalForcedFailureRate` sehingga pengujian unit test dan widget test dapat dijalankan secara instan tanpa kegagalan acak (*zero flakiness*). |
| **Desain Antarmuka Material 3** | Diperbaiki | Meningkatkan visualisasi kartu statistik menggunakan `Card`, `Container` dengan warna aksen tematik, dan ikon indikator yang jelas. |

---

## 4. Hasil Verifikasi Kode

- **`flutter analyze`**: Lolos tanpa peringatan (0 issues).
- **`flutter test`**: Semua unit test (`test/unit_test.dart`) dan widget test (`test/widget_test.dart`) lulus 100%.

---

## 5. Jawaban Refleksi

### 1. Kapan `setState` masih cukup, dan kapan state harus naik ke Riverpod?
- `setState` sangat ideal untuk **state lokal (ephemeral state)** yang hanya berdampak pada satu widget mandiri. Contohnya: membuka/menutup dialog lokal, state animasi transisi internal, atau penanganan controller form sementara (`TextEditingController`).
- State wajib dinaikkan ke **Riverpod (app-level state)** ketika:
  - Data harus diakses atau dimanipulasi oleh berbagai widget/halaman yang berbeda (misalnya daftar tugas ToDo yang ditampilkan di halaman utama dan dihitung di halaman statistik).
  - State harus tetap tersimpan (*persistent*) meskipun widget bersangkutan telah di-unmount dari widget tree.
  - Logika bisnis perlu diuji secara terisolasi tanpa merender antarmuka Flutter.

### 2. Apa perbedaan `context.go` dan `context.push`, dan kapan masing-masing tepat digunakan?
- **`context.go(path)`**: Bekerja secara deklaratif dengan mencocokkan URI tujuan terhadap konfigurasi router dan menggantikan stack rute sesuai hierarki path yang telah didefinisikan. Tepat digunakan untuk navigasi tingkat atas, perpindahan tab pada `NavigationBar`, redirect autentikasi, atau navigasi via deep link.
- **`context.push(path)`**: Bekerja secara imperatif dengan menumpuk rute baru di atas tumpukan navigasi saat ini (*push to stack*). Tepat digunakan untuk membuka alur detail atau sub-halaman bertingkat (misalnya membuka `/detail/:id`) di mana pengguna diharapkan dapat menekan tombol kembali (*back button*) untuk kembali ke layar sebelumnya.

### 3. Bagaimana `AsyncValue` mencegah bug dibanding tiga boolean terpisah?
- Pendekatan manual menggunakan tiga boolean terpisah (`isLoading`, `hasError`, `data`) rawan terhadap inkonsistensi status (misal `isLoading == true` bersamaan dengan `hasError == true`, atau lupa mengembalikan `isLoading = false` saat exception terjadi).
- `AsyncValue<T>` memodelkan status asinkron sebagai sebuah *discriminated union* yang hanya dapat berada dalam satu status pasti pada satu waktu: `AsyncLoading`, `AsyncError`, atau `AsyncData`. Metode `.when()` memaksa pengembang menangani semua kemungkinan status secara komprehensif saat kompilasi.

### 4. Bagian mana dari hasil AI yang Anda perbaiki, dan mengapa?
1. **Penyambungan State Riil**: Menghubungkan perhitungan statistik ke `todoListProvider`.
2. **Penggantian API Usang**: Menggunakan `ref.invalidate` dan method `refresh` berbasis `AsyncValue.guard`.
3. **Perbaikan Tipe dan Styling**: Memperbaiki deklarasi styling border `Border.all` dan kartu statistik Material 3.
