# AI Prompt Challenge — Minggu 4: Networking & REST API

Dokumentasi tanggung jawab teknis sesuai ketentuan codelab: prompt yang
diajukan, keluaran awal AI, verifikasi saya, serta perbaikan yang dilakukan.

**Aturan AI minggu ini:** AI boleh membantu merancang repository layer, tetapi
pengujian error handling, perbaikan logic, dan kemampuan menjelaskan setiap
keputusan teknis tetap menjadi tanggung jawab saya.

---

## 1. Prompt yang Diajukan

Prompt persis seperti yang diminta codelab (AI coding assistant, Claude Code):

```text
Buatkan repository layer Flutter untuk endpoint GET /comments?postId={id}
dari JSONPlaceholder menggunakan Dio + flutter_riverpod.
Requirements:
- Model Comment dengan fromJson aman null (postId, id, name, email, body).
- CommentRepository dengan method fetchComments(postId) + timeout 10 detik.
- AsyncNotifierProvider dengan penanganan error otomatis (AsyncError)
  dan fungsi pesan error
  ramah pengguna untuk timeout, connection error, 404, dan 500.
- Satu unit test untuk fromJson dengan field yang hilang.
Jelaskan setiap bagian kode dalam komentar.
```

---

## 2. Keluaran Awal AI (ringkasan)

AI menghasilkan 4 berkas: `comment.dart`, `comment_repository.dart`, penambahan
provider di `providers.dart`, dan `comment_test.dart`. Inti keluaran AI:

```dart
// Model — versi awal AI
factory Comment.fromJson(Map<String, dynamic> json) {
  return Comment(
    postId: (json['postId'] as num?)?.toInt() ?? 0,
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    body: json['body'] as String? ?? '',
  );
}

// Repository — versi awal AI (Dio dibuat baru di dalam repository)
class CommentRepository {
  Future<List<Comment>> fetchComments(int postId) async {
    final dio = Dio(BaseOptions(
      baseUrl: 'https://jsonplaceholder.typicode.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    final res = await dio.get<List>('/comments', queryParameters: {'postId': postId});
    ...
  }
}

// Provider — versi awal AI (family notifier tanpa argumen konstruktor)
final commentsProvider = AsyncNotifierProvider.family<CommentsNotifier,
    List<Comment>, int>(CommentsNotifier.new);
class CommentsNotifier extends AsyncNotifier<List<Comment>> {
  @override
  Future<List<Comment>> build() async => []; // postId tidak terbaca!
}
```

Serta satu unit test `fromJson` dengan `{'id': 3}` (field hilang).

---

## 3. AI Verification Checklist

| No | Poin Pemeriksaan | Hasil | Temuan & Tindakan |
|:--:|:---|:---:|:---|
| 1 | UI memanggil Dio langsung atau lewat repository? | **Lolos** | UI hanya `ref.watch` provider; Dio hanya dipakai di repository. |
| 2 | `fromJson` aman null? | **Diperbaiki** | Cast `(json['x'] as num?)` tetap crash saat server mengirim `"postId": "2"` (String). Dibuat helper `asInt`/`asString` di `lib/data/json_utils.dart` dan terbukti lulus pada edge case "field bertipe salah". |
| 3 | Semua `DioExceptionType` dipetakan ke pesan pengguna? | **Lolos** | `connectionTimeout`/`sendTimeout`/`receiveTimeout`, `connectionError`, `badResponse` (404, 401/403, 5xx), dan `default`. |
| 4 | `baseUrl`/timeout terpusat di satu client? | **Diperbaiki** | AI membuat `Dio` baru di dalam repository. Diganti dengan `createDio()` terpusat di `api_client.dart` milik minggu ini, sehingga timeout dan logging konsisten. |
| 5 | Notifier family bisa membaca `postId`? | **Diperbaiki** | Keluaran AI menyetel `build()` mengembalikan list kosong karena argumen tidak terbaca. Pada Riverpod 3.x argumen family masuk lewat konstruktor notifier: `CommentListNotifier(this.postId)`. |
| 6 | Test menguji kasus field hilang, bukan hanya happy path? | **Diperbaiki** | Test AI hanya 1 kasus. Ditambah: field hilang seluruhnya, field bertipe salah, pemetaan 404, pemetaan timeout, dan provider komentar error dengan repository palsu. |
| 7 | `flutter analyze` dan `flutter test` lolos tanpa warning? | **Lolos** | `No issues found!` dan `All tests passed!` (13 test). |

---

## 4. Perbaikan yang Saya Lakukan

1. **`Dio` dipusatkan.** Repository AI tidak boleh membuat `Dio` sendiri —
   konfigurasi pindah ke `createDio()` (`lib/data/api_client.dart`) lalu
   disuntikkan lewat `commentRepositoryProvider` (dependency injection).
2. **`fromJson` benar-benar aman.** Menjalankan test tambahan membuktikan
   pola `as num?` dari codelab masih crash pada tipe salah, sehingga saya
   menambah `asInt`/`asString`. Pola aman null tetap dipertahankan.
3. **Argumen family notifier.** `CommentListNotifier(this.postId)` +
   `AsyncNotifierProvider.family<...>(CommentListNotifier.new)`.
4. **Retry otomatis dimatikan** (`retry: (retryCount, error) => null`) agar
   error langsung final dan test tidak menggantung.
5. **UI detail halaman.** Komentar tampil di halaman `/post/:id` dengan tiga
   state sendiri: loading (spinner), error (pesan ramah), success (daftar
   `Card` komentar / "Belum ada komentar.").

## 5. Hasil Pengujian

```
$ flutter analyze
Analyzing week4_api...
No issues found! (ran in 6.0s)

$ flutter test -r expanded
00:00 +0: test/comment_test.dart : Comment.fromJson aman terhadap field yang hilang
00:00 +1: test/comment_test.dart : Comment.fromJson aman terhadap field bertipe salah
00:00 +2: test/comment_test.dart : friendlyErrorMessage memetakan 404 ke pesan ramah
00:00 +3: test/comment_test.dart : friendlyErrorMessage memetakan timeout ke pesan ramah
00:00 +4: test/comment_test.dart : provider komentar error dengan repository palsu
00:00 +5: test/post_test.dart    : fromJson aman terhadap field yang hilang
00:00 +6: test/post_test.dart    : friendlyErrorMessage untuk connection error
00:00 +7: test/post_test.dart    : provider sukses dengan repository palsu
00:00 +8: test/post_test.dart    : provider error dengan repository palsu
00:00 +9: test/widget_test.dart  : PostTile menampilkan id, judul, dan isi post
00:01 +10: test/widget_test.dart : PagedPostPage menampilkan data dari repository palsu
00:01 +11: test/widget_test.dart : PagedPostPage menampilkan pesan error + tombol retry
00:01 +12: test/widget_test.dart : PagedPostsState default: masih loading lebih & punya data
00:01 +13: All tests passed!
```

Test menggunakan `FakeCommentRepository` (override `commentRepositoryProvider`)
sehingga **tidak ada request HTTP sungguhan** di dalam test.
