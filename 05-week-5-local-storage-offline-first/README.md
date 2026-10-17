# Minggu 5: Local Storage & Offline-First

## Identitas Mahasiswa

- **Nama:** Reny Ambarwati
- **NIM:** 244107020066
- **Kelas:** TI-3F
- **Mata Kuliah:** Pemrograman Mobile

---

## Fitur Utama

- **CRUD catatan persisten** — tabel `notes` di SQLite; daftar selalu diurutkan
  `updated_at DESC` (terbaru di atas) dan bertahan setelah aplikasi ditutup.
- **Preferensi key-value** — toggle tema gelap/terang (`dark_mode`) dan catatan
  waktu terakhir dibuka (`last_opened_at`) di SharedPreferences.
- **Offline-first** — cache-first read `GET /posts` (endpoint Minggu 4),
  antrean sinkronisasi berbasis `dirty`, tombol **Sinkronkan** dengan laporan
  hasil, dan toggle **Paksa offline** untuk simulasi deterministik.
- **Empat state UI** — loading, error (+ tombol coba lagi), empty, success
  untuk data lokal maupun data API.
- **Halaman detail `/note/:id`** — membaca dari repository lokal, bukan dari
  state halaman daftar.

## Tujuan Pembelajaran

1. Menjelaskan perbedaan penyimpanan key-value, relasional, dan NoSQL di perangkat.
2. Menyimpan preferensi sederhana (tema, terakhir dibuka) dengan SharedPreferences.
3. Menerapkan CRUD catatan dengan SQLite (`sqflite`) melalui repository lokal.
4. Menerapkan pola offline-first: cache-first read, dirty flag, dan antrean sinkronisasi.
5. Menampilkan state loading, error, empty, dan success untuk data lokal dengan Riverpod.
6. Menguji repository lokal dengan repository palsu (tanpa database sungguhan).

## Stack Teknologi

| Komponen | Versi | Keterangan |
|---|---|---|
| Flutter (Dart) | 3.47.1 (3.13.1) | channel stable |
| `shared_preferences` | ^2.5.6 | preferensi key-value (tema, terakhir dibuka) |
| `sqflite` | ^2.4.4+2 | SQLite native Android/iOS |
| `sqflite_common_ffi_web` | ^1.2.0 | SQLite-wasm untuk demo web (lihat catatan di Langkah B2) |
| `path` | ^1.9.1 | `getDatabasesPath()` + `join` untuk lokasi database |
| `flutter_riverpod` | ^3.4.3 | state `AsyncValue` + provider |
| `dio` | ^5.11.1 | `GET /posts` (konfigurasi sama dengan Minggu 4) |
| `go_router` | ^18.0.2 | rute halaman detail `/note/:id` |
| `flutter_test` / `flutter_lints` | SDK / ^6.0.0 | unit test + provider test, lint baku |
| `playwright-core` (dev, `tool/`) | ^1.64.1 | pemotret screenshot layout mobile 390×844 |

## Struktur Folder

```
05-week-5-local-storage-offline-first/
├── week5_offline_notes/                # Project Flutter yang bisa dijalankan
│   ├── lib/
│   │   ├── main.dart                   # ProviderScope + GoRouter + tema dari prefs
│   │   ├── data/
│   │   │   ├── prefs.dart              # PrefsRepository (Langkah A1)
│   │   │   ├── providers.dart          # seluruh provider (lihat catatan deviasi)
│   │   │   ├── sync.dart               # cache-first + syncNotes (Refactoring #2)
│   │   │   ├── local/
│   │   │   │   ├── db.dart             # openNotesDb + skema (Langkah B2)
│   │   │   │   └── note.dart           # model Note + flag dirty (Langkah B1)
│   │   │   └── repositories/
│   │   │       └── note_repository.dart# satu-satunya pintu ke SQLite (Langkah B3)
│   │   ├── pages/
│   │   │   ├── home_shell.dart         # NavigationBar: Catatan/Postingan/Pengaturan
│   │   │   ├── notes_page.dart         # daftar + CRUD + badge dirty (Langkah B4)
│   │   │   ├── note_detail_page.dart   # /note/:id (Refactoring #3)
│   │   │   ├── posts_page.dart         # cache-first read (Langkah C1)
│   │   │   └── settings_page.dart      # preferensi + forceOffline (Langkah A2/C3)
│   │   └── widgets/
│   │       ├── note_tile.dart          # Refactoring #1 (+ badge belum tersinkron)
│   │       ├── offline_banner.dart     # banner "Mode offline aktif"
│   │       ├── sync_queue_bar.dart     # bar antrean + tombol Sinkronkan
│   │       └── format.dart             # pemformat waktu Indonesia
│   ├── test/
│   │   ├── note_test.dart              # 6 test: model + provider repository palsu
│   │   └── sync_test.dart              # 7 test: syncNotes + cache-first
│   ├── tool/
│   │   ├── capture.mjs                 # pemotret: satu skenario = satu screenshot
│   │   └── mobile_harness.html         # bingkai 390×844 (opsional, inspeksi manual)
│   └── pubspec.yaml
├── lib/                                # Salinan kode final (dokumentasi portofolio)
├── test/                               # Salinan test final
├── docs/
│   ├── ai_challenge.md                 # prompt, keluaran AI, verifikasi, keputusan
│   └── testing.md                      # output analyze/test + bukti skenario offline
├── screenshots/                        # 8 screenshot layout mobile 390×844
└── README.md
```

> Kode yang dapat dijalankan berada di subfolder `week5_offline_notes/`.
> Folder `lib/` dan `test/` di root berisi salinan final untuk dokumentasi
> portofolio, mengikuti konvensi minggu-minggu sebelumnya.

## Alur Data

```
UI (ConsumerWidget) --watch--> Provider (AsyncValue)
Provider --panggil--> NoteRepository / PrefsRepository --CRUD--> SQLite / SharedPreferences
Provider --cache-first--> sync.dart --GET /posts--> Dio (JSONPlaceholder)
syncNotes(dirty) --simulasi server sukses--> markAllSynced() → dirty = 0
```

UI **tidak pernah** memanggil SQLite, SharedPreferences, maupun Dio secara
langsung — hanya membaca provider. Repository adalah satu-satunya pintu data,
dan `openDb`-nya bisa disuntik sehingga seluruh test berjalan **tanpa database
sungguhan**.

### Pemilihan penyimpanan (ringkas)

| Kebutuhan | Pilihan | Alasan singkat |
|---|---|---|
| Tema gelap, waktu terakhir dibuka | `SharedPreferences` | nilai primitif kecil, dibaca sekali saat start |
| Catatan (koleksi, query, urutan, antrean sync) | `SQLite` via `sqflite` | relasi & query parsial (`updated_at DESC`, `WHERE dirty = 1`) |
| Cache 100 post dari API | tabel `cached_posts` di SQLite | payload JSON satu baris per post + `cached_at` |

Perbandingan penuh (vs Hive vs Drift) beserta penolakan alternatif ada di
[`docs/ai_challenge.md`](docs/ai_challenge.md).

---

## Bagian A — SharedPreferences

### Langkah A1 — Repository preferensi

Seluruh akses key-value dipusatkan di `PrefsRepository`
(`week5_offline_notes/lib/data/prefs.dart`), bukan tersebar di widget:

```dart
class PrefsRepository {
  static const _darkModeKey = 'dark_mode';
  static const _lastOpenedKey = 'last_opened_at';

  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? false;
  }

  Future<void> setDarkMode(bool value) async { ... }

  Future<void> markOpenedNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastOpenedKey, DateTime.now().toIso8601String());
  }

  Future<String?> getLastOpened() async { ... }
}
```

**Output (halaman Pengaturan setelah aplikasi dibuka —
[`02-pengaturan.png`](screenshots/02-pengaturan.png)):** baris *Terakhir
dibuka* menampilkan waktu dari kunci `last_opened_at` yang baru ditulis
`markOpenedNow()` saat aplikasi start, dan panel preferensi menegaskan
`dark_mode = false` bila tema belum pernah diubah.

### Langkah A2 — Provider tema + halaman pengaturan

```dart
class DarkModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.watch(prefsRepositoryProvider).getDarkMode();

  Future<void> toggle() async {
    final next = !(state.value ?? false);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(prefsRepositoryProvider).setDarkMode(next);
      return next;
    });
  }
}
```

`MaterialApp` membaca `darkModeProvider` di `main.dart`, jadi hasil toggle
langsung mengubah tema dan **bertahan setelah aplikasi dibuka ulang** (tersimpan
di SharedPreferences, bukan state sementara).

**Output (tema gelap tersimpan & dipakai ulang —
[`05-tema-gelap.png`](screenshots/05-tema-gelap.png)):** setelah toggle *Tema
gelap* di Pengaturan, halaman Catatan dirender penuh dalam skema gelap.

> **Catatan deviasi kecil:** modul menempatkan `prefsRepositoryProvider` dan
> `darkModeProvider` di dalam `settings_page.dart`. Karena tema juga
> dibutuhkan `MaterialApp` di `main.dart`, semua provider dipusatkan ke
> `lib/data/providers.dart` agar tidak terjadi import melingkar antar-halaman.
> Komentar penjelas disertakan tepat di file tersebut.

---

## Bagian B — SQLite (`sqflite`)

### Langkah B1 — Model catatan + flag `dirty`

Field `dirty` adalah jantung antrean sinkronisasi: `true` = perubahan lokal
belum terkirim ke "server".

```dart
class Note {
  final int? id;        // null = catatan baru yang belum masuk database
  final String title;
  final String body;
  final DateTime updatedAt; // urutan daftar + penentu konflik (LWW)
  final bool dirty;         // antrean sinkronisasi offline-first

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'body': body,
        'updated_at': updatedAt.toIso8601String(),
        'dirty': dirty ? 1 : 0,   // SQLite tidak punya tipe bool
      };

  factory Note.fromMap(Map<String, Object?> map) { ... } // aman null
}
```

**Output (`flutter test test/note_test.dart`, 2 test pertama lulus):**

```
00:00 +0: fromMap aman terhadap field yang hilang
00:00 +1: flag dirty bertahan pada serialisasi
```

### Langkah B2 — Pembuka database

Satu fungsi pembuka untuk seluruh repository (`lib/data/local/db.dart`), dengan
dua tabel: `notes` (CRUD + antrean sync) dan `cached_posts` (cache-first read).

```dart
Future<Database> openNotesDb() async {
  if (kIsWeb) {
    // Demo web: SQLite-wasm, persisten di IndexedDB.
    databaseFactory = databaseFactoryFfiWeb;
    return openDatabase(notesDbName, version: 1, onCreate: _onCreate);
  }
  final dir = await getDatabasesPath();
  return openDatabase(p.join(dir, notesDbName), version: 1, onCreate: _onCreate);
}
```

**Output (persiapan web — hanya dijalankan sekali sebelum build):**

```sh
dart run sqflite_common_ffi_web:setup
```

```
created: web/sqflite_sw.js (264107 bytes)
created: web/sqlite3.wasm (748686 bytes)
```

> **Mengapa ada cabang `kIsWeb`?** Mesin praktikum tidak memiliki emulator
> Android, sedangkan dokumentasi membutuhkan tampilan aplikasi di layout
> mobile. `sqflite` sendiri tidak mendukung web, jadi di browser factory
> diganti ke `databaseFactoryFfiWeb` (SQLite-wasm). Di **Android/iOS asli**
> cabang ini tidak aktif — `sqflite` native dipakai tanpa perubahan kode lain.

### Langkah B3 — Repository sebagai satu-satunya pintu data

`NoteRepository` mengekspos seluruh operasi yang dibutuhkan UI dan
sinkronisasi. Pengurutan daftar dan pembersihan antrean ada di tingkat query,
bukan di widget:

```dart
Future<List<Note>> fetchNotes() async {
  final db = await _openDb();
  final rows = await db.query('notes', orderBy: 'updated_at DESC');
  return rows.map(Note.fromMap).toList();
}

Future<int> countDirty() async {
  final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM notes WHERE dirty = 1');
  return ((rows.first['c'] as num?)?.toInt() ?? 0);
}

/// Dipanggil hanya setelah "server" menjawab sukses.
Future<void> markAllSynced() async {
  final db = await _openDb();
  await db.update('notes', {'dirty': 0}, where: 'dirty = 1');
}
```

**Output (log konsol saat CRUD — jejak audit yang bisa dibaca penguji):**

```
[notes] tambah #1 "Rencana praktikum Senin" → dirty = 1
[notes] 1 catatan dibaca dari SQLite
[notes] tambah #2 "Bahan presentasi offline-first" → dirty = 1
[notes] 2 catatan dibaca dari SQLite
```

**Output (bukti repository bisa diuji tanpa SQLite — repository palsu):**

```
00:00 +4: provider sukses dengan repository palsu
[notes] 1 catatan dibaca dari SQLite
00:00 +5: provider error dengan repository palsu
```

Constructor menerima `openDb` yang bisa disuntik, sehingga
`FakeNoteRepository` (yang `openDb`-nya melempar `UnimplementedError`)
membuktikan tidak ada database sungguhan yang tersentuh di dalam test.

### Langkah B4 — Halaman catatan offline (CRUD + badge)

Halaman Catatan (`notes_page.dart`) menampilkan: daftar `NoteTile` (dengan
badge "Belum tersinkron" bila `dirty`), baris ringkasan antrean
`SyncQueueBar` + tombol **Sinkronkan**, badge jumlah kotor di app bar, tombol
FAB **Tulis** untuk menambah catatan lewat dialog, dan tarik-turun untuk
refresh. Halaman tetap berfungsi penuh saat offline karena semua data lokal.

**Output (screenshot state empty dan tiga catatan kotor):**

| State empty (database bersih) | Tiga catatan, semua "Belum tersinkron" |
|---|---|
| ![State empty](screenshots/01-empty.png) | ![Tiga catatan kotor](screenshots/03-tiga-dirty.png) |

**Output (log pada skenario tiga catatan — `docs/testing.md`):**

```
[notes] tambah #3 "Daftar periksa rilis" → dirty = 1
[notes] 3 catatan dibaca dari SQLite
```

---

## Bagian C — Offline-first

### Langkah C1 — Cache-first read untuk data API

`loadPostsCacheFirst()` di `lib/data/sync.dart` membaca tabel `cached_posts`
lebih dulu sehingga **UI tidak pernah menunggu jaringan**:

```dart
final cached = (await source.readRows()).map(CachedPost.fromRow).toList();

if (forceOffline) {
  return cached;                     // offline: cache tetap tampil
}
if (cached.isEmpty && awaitFirstLoad) {
  return downloadPosts(source, fetchRemote); // kunjungan pertama: loading jujur
}
final fresh = isCacheFresh(cached, maxAge: maxAge);
if (!fresh && onBackgroundRefresh != null) {
  onBackgroundRefresh(downloadPosts(source, fetchRemote)); // refresh di background
}
return cached;
```

Tiga cabang di atas mencegah dua jebakan klasik: *empty-state* palsu saat
cache masih kosong, dan *invalidate loop* ketika refresh selesai selalu
memicu rebuild provider.

**Output (log + screenshot — 100 post tampil meski `forceOffline` aktif):**

```
[cache] cache kosong → ambil dari jaringan (state loading)
[cache] refresh jaringan OK → 100 post disimpan
[offline] forceOffline = true
[cache] offline → 100 post dari cache lokal
```

![Cache-first: 100 post dari cache lokal saat offline](screenshots/08-cache-posts.png)

### Langkah C2 — Sinkronisasi catatan kotor (dirty)

Karena codelab belum punya backend tulis, "server" disimulasikan dengan
delay — yang dinilai adalah mekanismenya:

```dart
Future<int> syncNotes(NoteRepository repo, {bool offline = false}) async {
  final dirtyCount = await repo.countDirty();
  if (offline) {
    debugPrint('[sync] mode offline → $dirtyCount catatan tetap antre');
    return 0;                        // antrean ditahan, UI tidak diblokir
  }
  if (dirtyCount == 0) return 0;
  await Future.delayed(const Duration(seconds: 1)); // simulasi upload
  await repo.markAllSynced();        // hanya dipanggil saat "sukses"
  return dirtyCount;
}
```

**Output (badge sebelum/sesudah sinkron — bukti mini project butir 4):**

| Sebelum: antrean 3, badge kotor per baris | Sesudah: "Semua 2 catatan tersinkron", badge 0 |
|---|---|
| ![Sebelum sinkron](screenshots/03-tiga-dirty.png) | ![Sesudah sinkron](screenshots/07-sinkron-selesai.png) |

**Output (log `syncNotes`):**

```
[sync] unggah 2 catatan (simulasi server) ...
[sync] selesai → dirty = 0 (last-write-wins: Last-Write-Wins (updated_at terbaru menang))
```

**Aturan konflik:** *last-write-wins* berdasarkan `updated_at`. Aturan ini
dijadikan konstanta `conflictRule` di `sync.dart`, diuji otomatis
(`aturan konflik last-write-wins memilih updated_at terbaru`), dan
ditampilkan di UI (halaman detail + bar antrean) supaya tidak pernah
"menimpa data secara diam-diam".

### Langkah C3 — Simulasi offline yang deterministik

Selain mode pesawat sungguhan di HP, aplikasi menyediakan toggle **Paksa
offline** (`forceOfflineProvider`) di Pengaturan — sesuai saran modul agar
demo tidak bergantung pada kondisi Wi-Fi kelas.

**Output (observasi skenario offline):**

| Langkah modul | Hasil observasi | Bukti |
|---|---|---|
| Matikan koneksi, buka aplikasi | Catatan tetap tampil, badge dirty akurat, banner "Mode offline aktif" | [`06-offline.png`](screenshots/06-offline.png) |
| Tulis/hapus catatan saat offline | Berhasil penuh (semua operasi lokal); catatan baru otomatis `dirty = 1` | log `[notes] tambah #1 "Ditulis saat mode pesawat" → dirty = 1` |
| Nyalakan koneksi, jalankan `syncNotes` | Badge kembali 0, daftar menampilkan "Tersinkron" | [`07-sinkron-selesai.png`](screenshots/07-sinkron-selesai.png) |
| `syncNotes` dijalankan saat offline | Antrean ditahan (`0` diunggah), `markAllSynced` tidak dipanggil | test `syncNotes saat offline menahan antrean` → log `[sync] mode offline → 1 catatan tetap antre` |

![Mode offline aktif: catatan lokal tetap tampil](screenshots/06-offline.png)

Pada HP/emulator asli, mematikan Wi-Fi/mengaktifkan mode pesawat melewati
jalur kode yang sama (tidak ada data yang dibaca dari jaringan untuk catatan),
sehingga hasilnya identik dengan toggle di atas.

---

## Refactoring Challenge

1. **Ekstrak `NoteTile`** (`lib/widgets/note_tile.dart`) — baris catatan
   menjadi widget tersendiri yang menampilkan judul, cuplikan isi, waktu
   `updated_at`, dan **badge "Belum tersinkron"** bila `dirty == true`
   (lihat [`01-empty.png`](screenshots/01-empty.png) dan
   [`03-tiga-dirty.png`](screenshots/03-tiga-dirty.png)).
2. **Pindahkan logika cache & sinkronisasi ke `lib/data/sync.dart`** —
   `NoteRepository` kembali fokus pada CRUD lokal; `sync.dart` berisi
   `loadPostsCacheFirst`, `downloadPosts`, `syncNotes`, `conflictRule`, dan
   `SyncReport`. Logika cache juga dipisah dari SQLite lewat abstraksi
   `PostCacheSource`, sehingga bisa diuji dengan sumber in-memory.
3. **Halaman detail `/note/:id` dengan GoRouter** — `noteDetailProvider`
   membaca catatan dari **repository lokal** berdasarkan `id` pada URL, bukan
   dari state halaman daftar, jadi deep link pun tetap menampilkan data yang
   benar.

![Halaman detail /note/:id dari repository lokal](screenshots/04-detail.png)

**Temuan tambahan saat dokumentasi:** pada versi awal, FAB *Tulis* berada di
bawah layar dan **menimpa tombol Sinkronkan** pada layout 390×844. Bar
antrean dipindah ke atas daftar (`SyncQueueBar` di atas `Expanded`) sehingga
kedua tombol selalu bisa ditekan — perbaikan terekam di
[`03-tiga-dirty.png`](screenshots/03-tiga-dirty.png).

---

## AI Prompt Challenge

Dokumentasi lengkap (prompt persis, output awal AI, tabel perbandingan final,
AI Verification Checklist, dan keputusan akhir) ada di
[`docs/ai_challenge.md`](docs/ai_challenge.md).

Ringkasan hasil:

- **Keputusan:** SharedPreferences untuk preferensi + `sqflite` (SQLite) untuk
  catatan & cache — kombinasi yang sama dengan rekomendasi AI, tetapi
  diverifikasi sendiri melalui kriteria modul (query, relasi, reaktivitas,
  type-safety, boilerplate, testing).
- **Ditolak dari keluaran AI:** saran menyimpan daftar catatan di
  SharedPreferences sebagai JSON tunggal (rapuh untuk query parsial & antrean
  sync), serta klaim "real-time" tanpa dukungan stream sungguhan.
- **Drift ditunda:** bagus untuk query kompleks + stream, tetapi boilerplate
  migrasi dan kurva belajar belum sepadan untuk skala aplikasi ini; Hive
  ditolak sebagai penyimpanan utama karena tidak memberi query SQL
  (`WHERE dirty = 1`, `ORDER BY updated_at DESC`) yang menjadi tulang punggung
  fitur minggu ini.
- **Skema yang diusulkan AI diverifikasi** mendukung antrean sync (kolom
  `dirty` + `updated_at`), bukan CRUD polos.

---

## Testing

```sh
cd week5_offline_notes
flutter analyze
flutter test -r expanded      # 13 test lulus
```

**Output `flutter analyze`:**

```
Analyzing week5_offline_notes...
No issues found! (ran in 5.5s)
```

**Output `flutter test` (dijalankan per file agar reporter tidak menabrak;
digabung hasilnya `00:00 +13: All tests passed!`):**

```
00:00 +0: fromMap aman terhadap field yang hilang
00:00 +1: flag dirty bertahan pada serialisasi
00:00 +2: aturan konflik last-write-wins memilih updated_at terbaru
00:00 +3: copyWith tidak mengubah id
00:00 +4: provider sukses dengan repository palsu
[notes] 1 catatan dibaca dari SQLite
00:00 +5: provider error dengan repository palsu
00:00 +6: All tests passed!          # test/note_test.dart

00:00 +0: syncNotes menandai semua catatan kotor sebagai sinkron
[sync] unggah 2 catatan (simulasi server) ...
[sync] selesai → dirty = 0 (last-write-wins: Last-Write-Wins (updated_at terbaru menang))
00:00 +1: syncNotes saat offline menahan antrean (dirty tetap ada)
[sync] mode offline → 1 catatan tetap antre
00:00 +2: syncNotes dengan antrean kosong tidak menyentuh database
[sync] antrean kosong, tidak ada yang diunggah
00:00 +3: cache-first offline: baca cache tanpa memanggil jaringan
[cache] offline → 1 post dari cache lokal
00:00 +4: cache-first: kunjungan pertama menunggu jaringan (state loading)
[cache] cache kosong → ambil dari jaringan (state loading)
[cache] refresh jaringan OK → 1 post disimpan
00:00 +5: cache basi memicu refresh di background, UI tetap dapat cache
[cache] 1 post dari cache lokal (hangat: false)
[cache] refresh jaringan OK → 1 post disimpan
00:00 +6: CachedPost dari payload rusak tetap aman
00:00 +7: All tests passed!          # test/sync_test.dart
```

Jauh melampaui minimal 2 test yang diminta modul (1 unit test model + 1 test
provider dengan repository palsu). Semua test berjalan **tanpa SQLite
sungguhan dan tanpa HTTP** — dibuktikan oleh `FakeNoteRepository` /
`InMemoryPostCacheSource` yang memblokir akses database. Rincian per test ada
di [`docs/testing.md`](docs/testing.md).

---

## Tangkapan Layar

Delapan screenshot diambil pada layout mobile **390×844** dengan
`tool/capture.mjs`. **Satu skenario = satu proses aplikasi → satu screenshot →
aplikasi ditutup**, sehingga setiap gambar berasal dari start yang bersih
(database IndexedDB kosong) dan hasilnya deterministik.

| # | Skenario | Yang dibuktikan |
|---|---|---|
| 01 | `empty` | State empty + antrean 0 saat database kosong |
| 02 | `pengaturan` | Kunci SharedPreferences: `last_opened_at` terisi, `dark_mode = false` |
| 03 | `tiga-dirty` | 3 catatan masuk SQLite, badge kotor per baris + badge jumlah |
| 04 | `detail` | `/note/:id` membaca dari repository lokal |
| 05 | `tema-gelap` | Tema dari SharedPreferences dipakai ulang |
| 06 | `offline` | `forceOffline`: banner offline + catatan lokal + badge akurat |
| 07 | `sinkron-selesai` | `syncNotes` mengosongkan antrean (badge 3 → 0) |
| 08 | `cache-posts` | Cache-first `GET /posts` tampil tanpa jaringan |

| | | |
|---|---|---|
| ![01 empty](screenshots/01-empty.png) **01 — Empty** | ![02 pengaturan](screenshots/02-pengaturan.png) **02 — Pengaturan** | ![03 tiga dirty](screenshots/03-tiga-dirty.png) **03 — Tiga catatan kotor** |
| ![04 detail](screenshots/04-detail.png) **04 — Detail `/note/:id`** | ![05 tema gelap](screenshots/05-tema-gelap.png) **05 — Tema gelap** | ![06 offline](screenshots/06-offline.png) **06 — Mode offline** |
| ![07 sesudah sinkron](screenshots/07-sinkron-selesai.png) **07 — Sesudah sinkron** | ![08 cache posts](screenshots/08-cache-posts.png) **08 — Cache-first posts** | |

---

## Cara Menjalankan

### Aplikasi (Android emulator / perangkat fisik) — jalur produksi

```sh
cd week5_offline_notes
flutter pub get
flutter run            # pilih emulator Android atau HP (USB debugging)
```

Jalur ini memakai `sqflite` native persis seperti yang dipelajari di modul;
tidak perlu setup tambahan apa pun.

### Build web untuk dokumentasi (tanpa emulator)

Karena mesin praktikum tidak memiliki emulator Android, aplikasi dibangun
sekali untuk web (SQLite-wasm + IndexedDB, lihat Langkah B2), lalu disajikan
secara statis:

```sh
cd week5_offline_notes
dart run sqflite_common_ffi_web:setup       # sekali saja
flutter build web --release
cd build\web
python -m http.server 8081 --bind 127.0.0.1
# buka http://127.0.0.1:8081/?semantics=true
```

Parameter `?semantics=true` mengaktifkan accessibility tree bawaan Flutter web
dari awal (`SemanticsBinding.ensureSemantics()` di `main.dart`), dipakai tool
pemotret untuk menekan tombol secara terprogram.

### Mengambil ulang screenshot (satu per satu)

```sh
cd week5_offline_notes/tool
npm install                                    # playwright-core (memakai Edge sistem)

node capture.mjs empty          ..\..\screenshots\01-empty.png
node capture.mjs pengaturan     ..\..\screenshots\02-pengaturan.png
node capture.mjs tiga-dirty     ..\..\screenshots\03-tiga-dirty.png
node capture.mjs detail         ..\..\screenshots\04-detail.png
node capture.mjs tema-gelap     ..\..\screenshots\05-tema-gelap.png
node capture.mjs offline        ..\..\screenshots\06-offline.png
node capture.mjs sinkron-selesai ..\..\screenshots\07-sinkron-selesai.png
node capture.mjs cache-posts    ..\..\screenshots\08-cache-posts.png
```

Setiap perintah membuka aplikasi di konteks browser baru (viewport 390×844,
device scale 2×), menjalankan satu skenario, memotret, lalu menutup
aplikasi. Log konsol `[notes]`/`[cache]`/`[sync]` ikut tercetak — log yang
sama dikutip sebagai output di dokumen ini. Skenario `probe`, `probe-dialog`,
`probe-list`, dan `probe-sync` bersifat diagnostik (mencetak accessibility
tree, tanpa screenshot).

---

## Checklist Verifikasi Mandiri

- [x] UI tidak memanggil SQLite/SharedPreferences langsung; semua lewat repository + provider.
- [x] Aplikasi penuh berfungsi dalam mode pesawat: baca, tambah, hapus catatan (screenshot `06-offline.png` + test offline sync).
- [x] Badge dirty akurat sebelum/sesudah sync (`03-tiga-dirty.png` → `07-sinkron-selesai.png`); cache posts tampil tanpa internet (`08-cache-posts.png`).
- [x] `flutter analyze` tanpa issue dan semua test lulus (13 test).
- [x] Hasil AI diverifikasi dan didokumentasikan pada folder `docs/`.

## Pemenuhan Mini Project / Industry Challenge

| Butir modul | Pemenuhan | Bukti |
|---|---|---|
| 1. Preferensi tema + terakhir dibuka | `PrefsRepository` + `DarkModeNotifier` + `LastOpenedNotifier` | [`02-pengaturan.png`](screenshots/02-pengaturan.png), [`05-tema-gelap.png`](screenshots/05-tema-gelap.png) |
| 2. CRUD SQLite via repository + Riverpod, urut `updated_at DESC` | `NoteRepository.fetchNotes(orderBy: 'updated_at DESC')` + `NotesNotifier` | [`01-empty.png`](screenshots/01-empty.png), [`03-tiga-dirty.png`](screenshots/03-tiga-dirty.png), [`04-detail.png`](screenshots/04-detail.png) |
| 3. Offline-first: cache-first, dirty flag + `syncNotes`, aturan konflik eksplisit | `lib/data/sync.dart` (`loadPostsCacheFirst`, `syncNotes`, `conflictRule`) | [`08-cache-posts.png`](screenshots/08-cache-posts.png), [`07-sinkron-selesai.png`](screenshots/07-sinkron-selesai.png), test `aturan konflik last-write-wins` |
| 4. Bukti mode pesawat: screenshot offline + badge sebelum/sesudah sync | Skenario `offline`, `tiga-dirty`, `sinkron-selesai` | [`06-offline.png`](screenshots/06-offline.png) + [`03`](screenshots/03-tiga-dirty.png) → [`07`](screenshots/07-sinkron-selesai.png) |
| 5. Minimal 2 test lulus | 13 test (6 model/provider + 7 sinkronisasi/cache) | [`docs/testing.md`](docs/testing.md) |
| 6. AI Challenge terdokumentasi | prompt, output awal AI, tabel perbandingan, checklist verifikasi, keputusan final | [`docs/ai_challenge.md`](docs/ai_challenge.md) |
| 7. Push ke repo portfolio dengan struktur `lib/`, `test/`, `docs/`, `README.md`, `screenshots/` | Struktur folder root sesuai permintaan | daftar folder di atas |

---

## Error Umum & Temuan Saat Pengembangan

| Temuan | Penyebab | Penyelesaian |
|---|---|---|
| FAB *Tulis* menimpa tombol *Sinkronkan* di layar 390×844 | Keduanya berada di posisi bawah layar | `SyncQueueBar` dipindah ke atas daftar sebelum `Expanded` |
| Tooltip Material ("Pengaturan", dst.) tertinggal di screenshot | Kursor masih mengeklik tab saat dipotret | Tool pemotret menggeser kursor ke titik netral + jeda 1,2 detik sebelum memotret |
| Refresh background bisa memicu *loop* invalidate | `invalidate` dari hasil fetch men-trigger rebuild lagi | Hasil refresh ditulis langsung ke `state` (`_settle`), bukan lewat `invalidate` |
| `flutter test` menampilkan nama test yang tertukar | Dua file test dieksekusi paralel oleh tester Dart | Dokumentasi memakai keluaran per file (`flutter test test/note_test.dart`) |
| `MissingPluginException` saat menjalankan di web | `sqflite` tidak mendukung web | Factory diganti `databaseFactoryFfiWeb` + `dart run sqflite_common_ffi_web:setup` |

---

## Refleksi

### 1. Mengapa daftar catatan tidak boleh disimpan di SharedPreferences?

SharedPreferences pada dasarnya map key-value berbasis XML/plist untuk nilai
primitif. Menyimpan daftar catatan sebagai satu string JSON di sana membuat
**query parsial mustahil dilakukan di tingkat penyimpanan** — menguruti
`updated_at DESC`, menghitung `WHERE dirty = 1`, atau mengubah satu catatan
berarti memuat, mem-parse, memodifikasi, dan menulis ulang seluruh string.
Selain lambat dan rawan korup parsial (tulis gagal di tengah → seluruh data
hilang), pendekatan itu juga memaksa semua data terbaca ke memori sekaligus.
Karena itu koleksi selalu masuk database, sedangkan SharedPreferences hanya
untuk nilai kecil seperti `dark_mode`.

### 2. Kapan cache-first cukup, kapan butuh strategi lain?

Cache-first cocok untuk data yang **boleh sedikit basi** dan bersifat
*replaceable* — daftar post, katalog, profil. UI tampil seketika dari cache,
selisih kebaruannya diperbarui diam-diam di background. Network-first (jaringan
dulu, cache sebagai cadangan) dibutuhkan ketika **kebaruan lebih penting
daripada kecepatan tampil**, misalnya harga tiket, saldo, atau kurs: di sini
UI harus menunggu jawaban server, dan cache hanya dipakai ketika jaringan
gagal. Pertimbangan lain: cache-first berisiko menampilkan harga lama beberapa
detik, sedangkan network-first membuat pengalaman *loading* terasa di setiap
kunjungan.

### 3. Bagaimana dirty flag berubah menjadi antrean sync tanpa memblokir UI? Kapan tabel outbox diperlukan?

Di aplikasi ini, `dirty = 1` pada baris catatan *adalah* antrean: `countDirty`
membaca ukurannya, `syncNotes` memprosesnya, dan `markAllSynced` membersihkannya
— semuanya berjalan di background task Riverpod sehingga UI tetap responsif
(bahkan `syncNotes` sengaja menghasilkan laporan `SyncReport` untuk snackbar,
bukan menghalangi gesture). Batasnya terlihat ketika sinkronisasi menjadi
**bermacam-macam**: menghapus catatan (butuh operasi `delete` di server),
mengunggah lampiran, atau menerapkan *retry backoff* per item — flag tunggal
`dirty` tidak punya ruang untuk menyimpan jenis operasi, urutan antar-item,
atau jumlah percobaan. Saat itulah tabel **outbox** terpisah (satu baris per
operasi dengan `type`, `payload`, `attempts`, `status`) menjadi perlu.

### 4. Bagian mana dari rekomendasi AI yang Anda tolak, dan mengapa?

Dua hal. Pertama, keluaran awal AI menyebut SharedPreferences layak untuk
"daftar catatan kecil" — saya tolak karena alasan butir 1 di atas: keputusannya
bukan soal ukuran, melainkan soal kebutuhan query parsial dan ketahanan
transaksi yang hanya dimiliki database. Kedua, AI mengklaim Drift "real-time
gratis" lewat stream; saya verifikasi bahwa klaim itu hanya benar jika seluruh
bacaan memang memakai `watch` — sedangkan aplikasi ini memilih model
`AsyncValue` eksplisit (baca sekali → tampilkan → refresh saat ada pemicu),
sehingga manfaat stream tidak terpakai dan boilerplate Drift (migrasi, codegen)
akan menjadi biaya tanpa guna. Rincian perbandingan dan verifikasinya ada di
[`docs/ai_challenge.md`](docs/ai_challenge.md).

---

## Referensi Pendukung

- [Codelab resmi Minggu 5 — Local Storage & Offline-First (JTI Polinema)](https://jti-polinema.github.io/flutter-codelab/05-minggu-5-local-storage-offline-first/index.html)
- [Slide Week 5: Local Storage & Offline First](https://jti-polinema.github.io/flutter-codelab/00-slides/Week_05_Local_Storage_Offline_First.html)
- [Flutter cookbook: Store key-value data](https://docs.flutter.dev/cookbook/persistence/key-value)
- [shared_preferences package](https://pub.dev/packages/shared_preferences)
- [sqflite package](https://pub.dev/packages/sqflite)
- [sqflite_common_ffi_web package](https://pub.dev/packages/sqflite_common_ffi_web)
- [Hive package (alternatif NoSQL)](https://pub.dev/packages/hive)
- [Drift package (alternatif reaktif)](https://pub.dev/packages/drift)
- [Riverpod: AsyncNotifier dan AsyncValue](https://riverpod.dev/docs/concepts/async_notifiers)
