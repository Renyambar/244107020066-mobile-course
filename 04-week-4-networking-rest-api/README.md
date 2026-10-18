# Minggu 4: Networking & REST API
## Identitas Mahasiswa

- **Nama:** Reny Ambarwati
- **NIM:** 244107020066
- **Kelas:** TI-3F
- **Mata Kuliah:** Pemrograman Mobile

## Tujuan Pembelajaran

1. Menjelaskan konsep HTTP, REST API, dan JSON.
2. Memetakan JSON ke model Dart (serialization) dengan aman null.
3. Menerapkan repository pattern dasar sehingga UI tidak memanggil API langsung.
4. Mengonfigurasi Dio (base URL, timeout, interceptor) dan menangani error jaringan.
5. Menampilkan state loading, error, empty, dan success dengan `AsyncValue` + Riverpod.
6. Menerapkan pagination dasar (infinite scroll).

## Stack Teknologi

| Komponen | Versi | Keterangan |
|---|---|---|
| Flutter (Dart) | 3.47.1 (3.13.1) | channel stable |
| `dio` | ^5.11.1 | HTTP client + interceptor |
| `flutter_riverpod` | ^3.4.3 | state management `AsyncValue` |
| `go_router` | ^18.0.2 | routing halaman detail `/post/:id` |
| `flutter_test` | SDK | unit test + widget test |

## Struktur Folder

```
04-week-4-networking-rest-api/
├── week4_api/                      # Project Flutter yang bisa dijalankan
│   ├── lib/
│   │   ├── main.dart               # ProviderScope + GoRouter (/ , /all, /post/:id)
│   │   ├── data/
│   │   │   ├── api_client.dart     # createDio() terpusat (base URL, timeout, logging)
│   │   │   ├── json_utils.dart     # asInt/asString — fromJson aman null & salah tipe
│   │   │   ├── network_errors.dart # friendlyErrorMessage (Refactoring #2)
│   │   │   ├── providers.dart      # dio, repository, PostListNotifier, comments
│   │   │   ├── paged_posts.dart    # PagedPostsState + PagedPostsNotifier (Langkah 8)
│   │   │   ├── models/             # post.dart, comment.dart
│   │   │   └── repositories/       # post_repository.dart, comment_repository.dart
│   │   ├── pages/                  # post_list_page, paged_post_page, post_detail_page
│   │   └── widgets/post_tile.dart  # Refactoring #1
│   ├── test/
│   │   ├── post_test.dart          # 4 test sesuai codelab
│   │   ├── comment_test.dart       # AI Challenge: fromJson + error mapping
│   │   └── widget_test.dart        # PostTile + PagedPostPage dengan fake repository
│   └── tool/
│       ├── mock_api.py             # mock REST API untuk uji loading/empty/error
│       └── mobile_harness.html     # bingkai 390x844 untuk screenshot layout mobile
├── lib/                            # Salinan kode final (dokumentasi portofolio)
├── test/                           # Salinan test final
├── docs/
│   └── ai_challenge.md             # Prompt, keluaran AI, verifikasi, perbaikan
├── screenshots/
└── README.md
```

## Langkah 1 — Model data dengan `fromJson` aman null

`Post` dan `Comment` memakai cast defensif, sehingga field yang hilang,
`null`, atau salah tipe tidak membuat crash `type 'Null' is not a subtype`.

```dart
factory Post.fromJson(Map<String, dynamic> json) => Post(
      userId: asInt(json['userId']),
      id: asInt(json['id']),
      title: asString(json['title']),
      body: asString(json['body']),
    );
```

## Langkah 2 — Konfigurasi Dio terpusat

Seluruh konfigurasi jaringan hidup di `api_client.dart`:

```dart
final dio = Dio(BaseOptions(
  baseUrl: 'https://jsonplaceholder.typicode.com',
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 10),
  headers: {'Accept': 'application/json'},
));
dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: false));
```
## Langkah 3 — Repository sebagai pintu data

`PostRepository` menyediakan `fetchPosts()`, `fetchPost(id)`, dan
`fetchPostsPage(page, limit)`. Exception sengaja **tidak ditelan** agar
menjadi `AsyncError` di provider.

## Langkah 4 — Provider `AsyncNotifier` + pesan error ramah

`PostListNotifier extends AsyncNotifier<List<Post>>` memanggil repository di
`build()`; Riverpod mengubah exception menjadi `AsyncError`. Retry otomatis
Riverpod 3 dimatikan (`retry: (retryCount, error) => null`) agar error langsung
final dan tidak menggantung saat diuji.

`friendlyErrorMessage()` memetakan `timeout`, `connectionError`, `404`,
`401/403`, dan `5xx` ke bahasa manusia.


## Langkah 5 & 6 — UI loading, error, empty, success

`ProviderScope` membungkus aplikasi; `PostListPage` membaca
`ref.watch(postListProvider)` lalu merender `postsAsync.when(...)`.

| State | Tampilan | Screenshot |
|---|---|---|
| loading | `CircularProgressIndicator` di tengah layar | [`01-loading.png`](screenshots/01-loading.png) |
| error | ikon + pesan ramah + tombol **Coba lagi** (`ref.invalidate`) | [`04-error.png`](screenshots/04-error.png), [`09-server-error.png`](screenshots/09-server-error.png) |
| empty | teks "Belum ada data dari server." | [`05-empty.png`](screenshots/05-empty.png) |
| success | daftar post (`PostTile`) dengan `RefreshIndicator` | [`02-success.png`](screenshots/02-success.png), [`07-all-posts.png`](screenshots/07-all-posts.png) |

![State success daftar post paginated](screenshots/02-success.png)

## Langkah 7 & 8 — Repository paginated + notifier state halaman

```dart
Future<List<Post>> fetchPostsPage({required int page, int limit = 10}) async {
  final response = await _dio.get<List<dynamic>>(
    '/posts',
    queryParameters: {'_page': page, '_limit': limit},
  );
  ...
}
```

`PagedPostsState` menyimpan `items`, `page`, `isLoadingMore`, `hasMore`, dan
`error` dalam satu objek immutable, sehingga data lama tetap tampil ketika
halaman berikutnya gagal.

## Langkah 9 — UI infinite scroll

`ScrollController` memicu `loadNextPage()` saat `extentAfter < 200`
(200px sebelum ujung list), dan item footer menampilkan indikator loading
atau teks "Semua data termuat.".

```dart
void _loadIfViewportNotFull() {
  if (!mounted || !_controller.hasClients) return;
  final state = ref.read(pagedPostsProvider);
  if (!state.hasMore || state.isLoadingMore) return;
  if (_controller.position.extentAfter < 200) {
    ref.read(pagedPostsProvider.notifier).loadNextPage();
  }
}
```

| Inifinite scroll (halaman 2–3 tampil) | Akhir data (100 post) |
|---|---|
| ![Pagination infinite scroll](screenshots/03-pagination.png) | ![Semua data termuat](screenshots/08-all-loaded.png) |

---

## Uji Tiga Skenario Error

| # | Skenario | Cara pengujian | Hasil |
|---|---|---|---|
| 1 | Internet normal | `flutter run` langsung ke `jsonplaceholder.typicode.com` | Daftar post tampil, infinite scroll menambah data, halaman detail + komentar termuat |
| 2 | Koneksi terputus | `flutter run ... --dart-define=API_BASE_URL=http://127.0.0.1:5051` lalu mock server dimatikan (persis seperti mematikan internet/mode pesawat) | "Tidak dapat terhubung ke server. Periksa internet Anda." + tombol **Coba lagi** |
| 3 | `baseUrl` salah / server gagal | Mock server sengaja membalas `500 Internal Server Error` pada `GET /posts?_page=...` | "Server bermasalah (500). Coba lagi nanti." + tombol **Coba lagi** |


![State error koneksi dan tombol coba lagi](screenshots/04-error.png)

![State error server 500 dan tombol coba lagi](screenshots/09-server-error.png)

![State empty](screenshots/05-empty.png)


![State loading](screenshots/01-loading.png)

---

## Refactoring Challenge

1. **Ekstrak `PostTile`** — widget baris post dipindah ke
   `lib/widgets/post_tile.dart` (parameter `post`, `onTap`, `showBody`), sehingga
   `ListView.builder` pendek dan widget bisa diuji terisolasi.
2. **Pindahkan `friendlyErrorMessage`** ke `lib/data/network_errors.dart`
   sehingga dipakai ulang oleh halaman penuh, halaman paginated, dan halaman detail.
3. **Halaman detail `/post/:id` dengan GoRouter** — menampilkan `title` dan
   `body` lengkap. Bila dibuka dari daftar, `Post` dikirim lewat `extra` sehingga
   tampil tanpa request ulang; bila dibuka langsung (deep link), post diambil
   ulang dari repository lewat `postDetailProvider`.

![Halaman detail post + komentar](screenshots/06-detail.png)



![Daftar penuh 100 post](screenshots/07-all-posts.png)


## AI Prompt Challenge

Dokumentasi lengkap (prompt, keluaran AI, checklist verifikasi, dan perbaikan)
ada di [`docs/ai_challenge.md`](docs/ai_challenge.md).

Ringkasan perbaikan terhadap keluaran AI:

- `Dio` dipusatkan ke `createDio()` (AI membuat Dio baru di dalam repository).
- `fromJson` dibuat aman terhadap tipe salah, bukan hanya `null`.
- Argumen family notifier diperbaiki: `CommentListNotifier(this.postId)`.
- Test ditambah: field hilang, field salah tipe, 404, timeout, provider error.

---

## Tangkapan Layar

| | | |
|---|---|---|
| ![Loading](screenshots/01-loading.png) **01 — Loading** | ![Success](screenshots/02-success.png) **02 — Success** | ![Error koneksi](screenshots/04-error.png) **04 — Error koneksi** |
| ![Pagination](screenshots/03-pagination.png) **03 — Pagination (halaman 2–3)** | ![Empty](screenshots/05-empty.png) **05 — Empty** | ![Server error](screenshots/09-server-error.png) **09 — Server error 500** |
| ![Detail](screenshots/06-detail.png) **06 — Detail + komentar** | ![Semua data termuat](screenshots/08-all-loaded.png) **08 — Semua data termuat** | ![Daftar penuh](screenshots/07-all-posts.png) **07 — Daftar penuh `/all`** |


## Refleksi

### 1. Mengapa UI dilarang memanggil Dio langsung?

Karena UI jadi sulit diuji (butuh jaringan sungguhan), sulit mengganti sumber
data, dan pemetaan error tersebar di banyak widget sehingga rawan duplikasi dan
terlewat. Dengan repository, UI hanya bergantung pada provider sehingga bisa
diuji dengan repository palsu dan seluruh kebijakan jaringan berada di satu tempat.

### 2. Kapan pagination client-side cukup, kapan harus server-side?

Client-side cukup bila data kecil dan sudah dimuat sekaligus (mis. < 100 item
yang jarang berubah). Pagination server (`_page`/`_limit`) wajib ketika data
besar: hanya halaman yang dibutuhkan yang dikirim, sehingga konsumsi memori,
pemakaian kuota, dan waktu muat awal tetap hemat.

### 3. Bagaimana exception repository berubah menjadi `AsyncError` tanpa try/catch di setiap widget?

`AsyncNotifier.build` yang melempar exception otomatis ditangkap Riverpod dan
diubah menjadi `AsyncError`. `try/catch` eksplisit tetap dibutuhkan ketika kita
ingin bereaksi secara khusus, misalnya di `refresh()` (menetapkan `AsyncLoading`
lalu memilih mempertahankan data lama saat gagal) atau di `loadNextPage()`
(agregasi state halaman: data lama dipertahankan + error dicatat).

### 4. Bagian mana dari hasil AI yang Anda perbaiki, dan mengapa?

`Dio` dibuat ulang di dalam repository (diganti `createDio()` terpusat),
`fromJson` hanya aman null tapi crash pada tipe salah, family notifier tidak bisa membaca `postId`, dan test AI hanya happy path (ditambah 404, timeout, field hilang,
serta provider error dengan repository palsu). Detailnya di
[`docs/ai_challenge.md`](docs/ai_challenge.md).
