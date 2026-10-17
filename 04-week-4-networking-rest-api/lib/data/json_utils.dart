/// Helper pemetaan JSON yang lebih defensif daripada cast langsung.
///
/// Cast `(json['x'] as num?)` dari codelab hanya aman terhadap `null`.
/// Pengujian edge case di `test/comment_test.dart` membuktikan bahwa cast
/// tersebut tetap crash bila server mengirim `"postId": "2"` (String)
/// dengan error `type 'String' is not a subtype of type 'num?'`.
///
/// Kedua helper ini menangani `null`, salah tipe, dan String numerik
/// sekaligus, sehingga model tetap "aman null" sekaligus "aman salah tipe".
int asInt(Object? value, [int fallback = 0]) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

String asString(Object? value, [String fallback = '']) {
  if (value is String) return value;
  if (value == null) return fallback;
  return value.toString();
}
