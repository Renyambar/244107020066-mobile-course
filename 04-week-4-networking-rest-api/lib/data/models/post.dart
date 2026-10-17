import '../json_utils.dart';

/// Langkah 1 codelab — Model data dengan `fromJson` aman null.
///
/// Sumber data: JSONPlaceholder `GET /posts` yang mengembalikan
/// `userId`, `id`, `title`, dan `body`.
class Post {
  const Post({
    required this.userId,
    required this.id,
    required this.title,
    required this.body,
  });

  final int userId;
  final int id;
  final String title;
  final String body;

  /// Memetakan JSON mentah (`Map<String, dynamic>`) ke objek [Post].
  ///
  /// Cast dibuat defensif lewat helper `asInt`/`asString`:
  /// - field hilang / `null` → dipakai nilai default (`0` / `''`),
  /// - server mengirim String numerik (`"id": "7"`) → tetap terkonversi,
  /// - server mengirim tipe tak terduga → tidak membuat crash.
  ///
  /// Tanpa pola ini, respons API yang tidak sesuai dokumentasi membuat
  /// aplikasi crash dengan `type 'Null' is not a subtype of type 'String'`
  /// — sumber bug paling umum pada integrasi API pertama.
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      userId: asInt(json['userId']),
      id: asInt(json['id']),
      title: asString(json['title']),
      body: asString(json['body']),
    );
  }

  /// Serialisasi balik, dipakai untuk logging `requestBody`/`responseBody`
  /// dan memudahkan pengujian (mis. repository palsu).
  Map<String, dynamic> toJson() => {
        'userId': userId,
        'id': id,
        'title': title,
        'body': body,
      };

  @override
  String toString() => 'Post(id: $id, userId: $userId, title: "$title")';
}
