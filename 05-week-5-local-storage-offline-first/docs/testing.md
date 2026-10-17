# Testing & Verifikasi — Week 5 (Offline Notes)

Dokumen ini memuat **hasil pengujian otomatis** dan **bukti pengujian manual
skenario offline** sesuai *Checklist verifikasi mandiri* codelab Minggu 5.

---

## 1. `flutter analyze`

```sh
cd week5_offline_notes
flutter analyze
```

**Output:**

```
Analyzing week5_offline_notes...
No issues found! (ran in 5.5s)
```

## 2. `flutter test`

```sh
flutter test test/note_test.dart -r expanded
flutter test test/sync_test.dart -r expanded
```

Dijalankan per file agar keluaran reporter tidak saling menabrak (kedua file
sebenarnya dieksekusi paralel). Jika digabung dengan
`flutter test -r expanded` hasilnya tetap sama: `00:00 +13: All tests passed!`.

**Output `test/note_test.dart` — 6 test lulus:**

```
00:00 +0: loading .../week5_offline_notes/test/note_test.dart
00:00 +0: fromMap aman terhadap field yang hilang
00:00 +1: flag dirty bertahan pada serialisasi
00:00 +2: aturan konflik last-write-wins memilih updated_at terbaru
00:00 +3: copyWith tidak mengubah id
00:00 +4: provider sukses dengan repository palsu
[notes] 1 catatan dibaca dari SQLite
00:00 +5: provider error dengan repository palsu
00:00 +6: All tests passed!
```

**Output `test/sync_test.dart` — 7 test lulus:**

```
00:00 +0: loading .../week5_offline_notes/test/sync_test.dart
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
00:00 +7: All tests passed!
```

> Path absolut pada keluaran asli dipotong menjadi `.../week5_offline_notes/test/...`.

### Yang diuji

| Kelompok | Test | Yang dibuktikan |
|---|---|---|
| Unit model | `fromMap aman terhadap field yang hilang` | Kolom hilang tidak membuat crash (aman null) |
| Unit model | `flag dirty bertahan pada serialisasi` | `dirty` lolos `toMap` → `fromMap` (antrean sync tidak hilang) |
| Unit model | `aturan konflik last-write-wins memilih updated_at terbaru` | Aturan konflik terdokumentasi & bekerja |
| Unit model | `copyWith tidak mengubah id` | Immutability objek catatan |
| Provider | `provider sukses dengan repository palsu` | `notesProvider` + `dirtyCountProvider` dari fake repository |
| Provider | `provider error dengan repository palsu` | Exception repository → `AsyncError` (halaman error + retry) |
| Sinkronisasi | `syncNotes menandai semua catatan kotor sebagai sinkron` | `markAllSynced` dipanggil sekali, badge kembali 0 |
| Sinkronisasi | `syncNotes saat offline menahan antrean (dirty tetap ada)` | Antrean ditahan saat offline, `markAllSynced` **tidak** dipanggil |
| Sinkronisasi | `syncNotes dengan antrean kosong tidak menyentuh database` | Tidak ada kerja sia-sia saat sudah bersih |
| Cache-first | `cache-first offline: baca cache tanpa memanggil jaringan` | `fetchRemote` dipanggil 0 kali saat offline |
| Cache-first | `cache-first: kunjungan pertama menunggu jaringan` | Cache kosong + online → loading jujur, hasil disimpan ke cache |
| Cache-first | `cache basi memicu refresh di background, UI tetap dapat cache` | UI tampil dari cache, refresh jalan di belakang |
| Model cache | `CachedPost dari payload rusak tetap aman` | JSON korup tidak membuat crash |

Kedua kelompok wajib codelab ikut terpenuhi: **1 unit test model** (`note_test`)
dan **1 test provider dengan repository palsu** — keduanya memakai
`FakeNoteRepository` / `SyncFakeRepository` yang `openDb`-nya melempar
`UnimplementedError`, sehingga membuktikan tidak ada SQLite yang tersentuh.

---

## 3. Bukti skenario offline (screenshot satu per satu)

Aplikasi dijalankan sebagai aplikasi web (build `flutter build web --release`,
disajikan statis di `http://127.0.0.1:8081`) lalu dipotret pada **layout mobile
390×844** memakai `tool/capture.mjs`. **Satu skenario = satu proses aplikasi →
satu screenshot → aplikasi ditutup**, jadi setiap gambar berasal dari start
aplikasi yang bersih (konteks browser baru, database kosong).

| # | Skenario (perintah) | Yang dibuktikan | Screenshot |
|---|---|---|---|
| 1 | `node capture.mjs empty 01-empty.png` | Start aplikasi dengan database kosong → state **empty** + antrean 0 | [`01-empty.png`](../screenshots/01-empty.png) |
| 2 | `node capture.mjs pengaturan 02-pengaturan.png` | `markOpenedNow()` mencatat waktu buka; kunci `dark_mode` masih `false` | [`02-pengaturan.png`](../screenshots/02-pengaturan.png) |
| 3 | `node capture.mjs tiga-dirty 03-tiga-dirty.png` | 3 catatan masuk SQLite, badge **Belum tersinkron** per baris + badge jumlah di app bar | [`03-tiga-dirty.png`](../screenshots/03-tiga-dirty.png) |
| 4 | `node capture.mjs detail 04-detail.png` | Rute `/note/:id` membaca catatan dari repository lokal | [`04-detail.png`](../screenshots/04-detail.png) |
| 5 | `node capture.mjs tema-gelap 05-tema-gelap.png` | Toggle tema tersimpan di SharedPreferences dan dipakai ulang | [`05-tema-gelap.png`](../screenshots/05-tema-gelap.png) |
| 6 | `node capture.mjs offline 06-offline.png` | `forceOffline`: catatan lokal tetap tampil, badge dirty tetap akurat | [`06-offline.png`](../screenshots/06-offline.png) |
| 7 | `node capture.mjs sinkron-selesai 07-sinkron-selesai.png` | `syncNotes` mengosongkan antrean (badge 3 → 0) | [`07-sinkron-selesai.png`](../screenshots/07-sinkron-selesai.png) |
| 8 | `node capture.mjs cache-posts 08-cache-posts.png` | Cache-first `GET /posts` tampil tanpa jaringan | [`08-cache-posts.png`](../screenshots/08-cache-posts.png) |

### Log konsol aplikasi (bukti "output langkah")

Log berikut dicatat tool capture langsung dari konsol browser — bukan salinan
manual. Skenario 3 (`tiga-dirty`):

```
[notes] 0 catatan dibaca dari SQLite
[cache] cache kosong → ambil dari jaringan (state loading)
[cache] refresh jaringan OK → 100 post disimpan
[notes] tambah #1 "Rencana praktikum Senin" → dirty = 1
[notes] 1 catatan dibaca dari SQLite
[notes] tambah #2 "Bahan presentasi offline-first" → dirty = 1
[notes] 2 catatan dibaca dari SQLite
[notes] tambah #3 "Daftar periksa rilis" → dirty = 1
[notes] 3 catatan dibaca dari SQLite
```

Skenario 6 (`offline`) — toggle `forceOffline` otomatis membangun ulang
provider cache, dan cache dibaca **tanpa menyentuh jaringan**:

```
[offline] forceOffline = true
[cache] offline → 100 post dari cache lokal
```

Skenario 7 (`sinkron-selesai`) — `syncNotes` mengosongkan antrean:

```
[notes] tambah #1 "Perubahan pertama" → dirty = 1
[notes] 1 catatan dibaca dari SQLite
[notes] tambah #2 "Perubahan kedua" → dirty = 1
[notes] 2 catatan dibaca dari SQLite
[sync] unggah 2 catatan (simulasi server) ...
[sync] selesai → dirty = 0 (last-write-wins: Last-Write-Wins (updated_at terbaru menang))
[notes] 2 catatan dibaca dari SQLite
```

Skenario 8 (`cache-posts`) — sekali online untuk mengisi cache, lalu offline
semua konten tetap tampil dari `cached_posts`:

```
[cache] cache kosong → ambil dari jaringan (state loading)
[cache] refresh jaringan OK → 100 post disimpan
[offline] forceOffline = true
[cache] offline → 100 post dari cache lokal
```

> Semua log berasal dari `debugPrint` di `lib/data/sync.dart`,
> `lib/data/repositories/note_repository.dart`, dan `lib/data/providers.dart` —
> sengaja dipasang sebagai jejak audit yang bisa dibaca penguji.
> Varian *offline* untuk `syncNotes` sendiri diverifikasi otomatis oleh test
> `syncNotes saat offline menahan antrean (dirty tetap ada)`: output
> `[sync] mode offline → 1 catatan tetap antre` tanpa memanggil `markAllSynced`.

---

## 4. Mengapa SQLite bisa berjalan di browser (catatan teknis)

`sqflite` tidak mendukung web. Untuk demo/screenshot di mesin praktikum yang
tidak memiliki emulator Android, `lib/data/local/db.dart` menukar factory
default:

```dart
if (kIsWeb) {
  databaseFactory = databaseFactoryFfiWeb; // SQLite-wasm, persisten di IndexedDB
  return openDatabase(notesDbName, version: 1, onCreate: _onCreate);
}
```

Yang perlu dijalankan sekali sebelum build web:

```sh
dart run sqflite_common_ffi_web:setup
```

```
Fetching: https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.6.0/sqlite3.wasm
created: web/sqflite_sw.js (264107 bytes)
created: web/sqlite3.wasm (748686 bytes)
```

Di **Android/iOS asli** kode yang sama memakai `sqflite` native tanpa perubahan
apa pun — cabang `kIsWeb` hanya dijalankan di browser. Karena itulah
`flutter run` di HP/emulator tetap menjadi jalur produksi, sedangkan jalur web
dipakai untuk dokumentasi.
