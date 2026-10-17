# AI Prompt Challenge — Week 5 (Local Storage & Offline-First)

Dokumen ini menyimpan **prompt yang dipakai, output awal AI, tabel perbandingan
final, hasil verifikasi, dan keputusan akhir** sesuai ketentuan codelab
[Minggu 5](https://jti-polinema.github.io/flutter-codelab/05-minggu-5-local-storage-offline-first/index.html).

---

## 1. Prompt yang digunakan

Prompt diambil persis dari bagian *AI Prompt Challenge* modul:

```text
Aplikasi Flutter Offline Notes: CRUD catatan + preferensi tema.
Bandingkan SharedPreferences, Hive, sqflite (SQLite), dan Drift
untuk dua kebutuhan ini. Requirements:
- Kriteria: kompleksitas query, kebutuhan relasi, reaktivitas (stream),
  type-safety, ukuran boilerplate, dan kemudahan testing.
- Beri rekomendasi final: mana untuk preferensi, mana untuk catatan,
  beserta alasannya dalam 1 tabel.
- Tunjukkan skema tabel/kotak untuk 1000+ catatan.
Jelaskan trade-off setiap pilihan.
```

## 2. Output awal AI (yang saya terima, sebelum diverifikasi)

Ringkasan jawaban AI (draft):

- **Preferensi → SharedPreferences.** Cepat, tanpa boilerplate, cocok untuk
  `dark_mode` dan `last_opened_at`.
- **Catatan → Hive.** Alasan AI: "lebih ringan dari SQLite, sudah type-safe
  dengan adapter, dan bisa pakai `Box.watch` untuk reaktivitas real-time".
- Skema yang diusulkan AI:

```dart
// usulan awal AI (DITOLAK — lihat bagian 4)
class NoteAdapter extends TypeAdapter<Note> { ... }   // Hive
final box = await Hive.openBox<Note>('notes');
box.put(note.id, note);
```

- Saran AI: "karena hanya menampilkan daftar, query SQL tidak diperlukan;
  simpan seluruh daftar di SharedPreferences agar lebih sederhana" (usulan
  kedua ini langsung saya tolak).

Saya **tidak menerima** rekomendasi AI apa pun sebelum memverifikasi kebutuhan
aplikasi nyata (urutan `updated_at DESC`, hitung baris `dirty`, perbarui
sebagian kolom per catatan, dan cache 1000+ post).

## 3. Tabel perbandingan final (hasil verifikasi saya)

| Kriteria | SharedPreferences | Hive | **sqflite (SQLite)** | Drift |
|---|---|---|---|---|
| Kompleksitas query | Tidak ada query — baca/tulis per kunci | Filter di memori (`box.values.where`) | SQL penuh: `WHERE`, `ORDER BY`, `COUNT`, index | SQL penuh + codegen |
| Kebutuhan relasi | Tidak bisa | Harus manual (map id → objek) | Relasi & `JOIN` bawaan | Relasi kuat via `Table` |
| Reaktivitas (stream) | Tidak ada; harus poll/invalidate manual | `Box.watch()` ringan per kotak | Tidak bawaan → refresh via provider | `watch()` per query |
| Type-safety | Manual (`getBool`/`setString` + cast) | Baik (adapter hasil codegen) | `Map<String, Object?>` + cast manual | Sangat kuat (row class hasil codegen) |
| Boilerplate | Terkecil | Sedang (adapter + init) | Sedang (`toMap`/`fromMap` + SQL) | Besar saat awal (`build_runner`), kecil setelahnya |
| Kemudahan testing | Sangat mudah (`setMockInitialValues`) | Mudah (in-memory box) | Sedang — butuh injeksi `openDb` | Mudah (`NativeDatabase.memory`) |
| Kinerja 1000+ catatan | Buruk bila daftar disimpan 1 string JSON | Baik per objek | Baik (index + query per baris) | Baik |
| Risiko utama | Rapuh untuk koleksi: update 1 field menulis ulang seluruh blob & menghapus antrian sync | Skema tak beraturan, tanpa SQL, migrasi manual | SQL manual, rawan salah query | Dependensi berat + build step tambahan |

## 4. AI Verification Checklist

| # | Pertanyaan verifikasi | Temuan |
|---|---|---|
| 1 | Apakah AI menempatkan daftar catatan di SharedPreferences? | **Ya (usulan kedua) → saya tolak.** Menyimpan daftar sebagai string JSON di SharedPreferences membuat query parsial mustahil: mengubah 1 field harus menulis ulang seluruh blob, dan 1 typo JSON menghilangkan semua data. Bukti penerapan: `PrefsRepository` hanya memuat 2 kunci primitif (`dark_mode`, `last_opened_at`); catatan hidup di tabel `notes`. |
| 2 | Apakah skema mendukung antrean sync (dirty flag / `updated_at`), bukan CRUD polos? | **Hive (rekomendasi AI): tidak didukung secara langsung** — tidak ada `COUNT(*) WHERE dirty = 1`, harus difilter di memori tiap kali. Implementasi saya menambah kolom `dirty INTEGER` + `updated_at TEXT` (lihat `lib/data/local/db.dart`), diverifikasi test `syncNotes menandai semua catatan kotor sebagai sinkron` dan `flag dirty bertahan pada serialisasi`. |
| 3 | Apakah klaim "real-time" didukung stream? | **Tidak.** Klaim AI merujuk `Box.watch()`, tetapi aplikasi ini tidak membutuhkan stream per baris — cukup `ref.invalidate(notesProvider)` setelah mutasi (pola Riverpod yang sudah dipakai sejak Minggu 3). Karena itu kata "real-time" saya hapus dari dokumentasi; yang dipakai adalah refresh terkontrol. |
| 4 | Apakah estimasi boilerplate masuk akal setelah dicoba? | **Tidak untuk Drift.** `flutter pub add sqflite` selesai tanpa build step; Drift menambah `build_runner`, `dev_dependencies`, dan file `.g.dart`. Verifikasi nyata: model `Note` hanya ~40 baris (`toMap`/`fromMap`), sedangkan setup Drift butuh minimal 2 file tambahan + 1 kali codegen. |
| 5 | Keputusan final, boleh beda dari rekomendasi AI? | **Ya.** Saya memakai **SharedPreferences (preferensi) + sqflite/SQLite (catatan & cache post)**, bukan Hive sesuai usulan AI. Alasan lengkap di bagian 5. |

## 5. Keputusan final dan alasannya

**Kebutuhan A — preferensi (tema, waktu terakhir dibuka)** →
`SharedPreferences`.

- Hanya nilai primitif (`bool`, `String ISO-8601`), tidak ada query.
- Biaya terkecil: tanpa skema, tanpa migrasi, tersedia di seluruh platform.
- Diuji otomatis oleh aplikasi: kunci `dark_mode` & `last_opened_at` terbaca
  kembali setelah aplikasi ditutup (lihat screenshot Pengaturan).

**Kebutuhan B — catatan & cache post (koleksi, berubah per baris)** →
`sqflite (SQLite)`.

- Butuh `ORDER BY updated_at DESC`, `COUNT(*) WHERE dirty = 1`, dan update
  **per baris** (edit 1 catatan tidak boleh menyentuh catatan lain) — semua
  mustahil dilakukan rapi di SharedPreferences.
- Antrean sinkronisasi butuh kolom `dirty` + `updated_at` sebagai data
  terstruktur, bukan bagian dari string JSON.
- Tabel `cached_posts` menyimpan cache-first `GET /posts` (endpoint Minggu 4)
  sehingga halaman Postingan tetap tampil saat mode pesawat.
- Mudah diuji: constructor `NoteRepository({openDb})` menyuntikkan database
  palsu sehingga 13 test lulus tanpa SQLite sungguhan.

**Kenapa bukan Hive (rekomendasi AI)?**

1. Skema sync harus dibangun manual di atas map objek (`dirty` tidak punya
   tempat baku), padahal itu inti materi minggu ini.
2. `Box.watch()` memberi reaktivitas per kotak, bukan per query; untuk daftar
   1000+ catatan hal itu justru memicu rebuild berlebih.
3. sqflite lebih dekat ke SQL yang diajarkan di kelas dan tidak menambah
   dependensi adapter.

**Kenapa bukan Drift?**

Drift jawaban teknis yang paling "benar" untuk aplikasi besar (type-safe,
`watch()` per query), tetapi biaya masuknya (build_runner + codegen) tidak
sebanding untuk aplikasi catatan dengan 2 tabel. Saya catat Drift sebagai
kandidat upgrade bila kelak butuh query kompleks berantai.

## 6. Skema untuk 1000+ catatan

Implementasi (lihat `lib/data/local/db.dart`):

```sql
CREATE TABLE notes(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  body TEXT NOT NULL DEFAULT '',
  updated_at TEXT NOT NULL,          -- ISO-8601, sekaligus kunci konflik
  dirty  INTEGER NOT NULL DEFAULT 0  -- penanda antrean sinkronisasi
);
CREATE TABLE cached_posts(
  id INTEGER PRIMARY KEY,
  payload TEXT NOT NULL,             -- JSON utuh, ditulis saat refresh
  cached_at TEXT NOT NULL
);
```

Rekomendasi tambahan yang saya dokumentasikan (belum dipasang agar skema tetap
sama persis dengan modul):

```sql
CREATE INDEX idx_notes_updated_at ON notes(updated_at DESC); -- halaman utama
CREATE INDEX idx_notes_dirty      ON notes(dirty);          -- hitung antrean
```

- Index di atas membuat `ORDER BY updated_at DESC` dan `COUNT(*) WHERE dirty=1`
  tetap O(log n) saat catatan >1000.
- Alternatif: simpan `updated_at` sebagai INTEGER epoch-millisecond agar index
  lebih rapat — saya pilih ISO-8601 karena mudah dibaca saat debugging, dan
  urutan lexikal ISO-8601 identik dengan urutan kronologis.
- Untuk daftar sangat besar, lanjutkan dengan `LIMIT/OFFSET` (paging), bukan
  membaca seluruh tabel sekaligus.

## 7. Bagian yang saya ubah/ditolak dari output AI

| Usulan AI | Keputusan saya | Alasan |
|---|---|---|
| Simpan daftar catatan di SharedPreferences | Ditolak | Rapuh untuk koleksi; update parsial merusak antrian sync |
| Catatan → Hive | Diganti **sqflite** | Butuh query `dirty`/`updated_at` & update per baris |
| `Box.watch` = real-time | Tidak dipakai | Cukup `ref.invalidate(notesProvider)`; tidak butuh stream per baris |
| Drift untuk proyek ini | Ditunda | Codegen berlebih untuk 2 tabel |
| Tanpa kolom dirty (sync dihitung dari luar) | Ditambahkan | Codelab mewajibkan dirty flag + antrean |
