import '../json_utils.dart';

/// Model tambahan hasil AI Prompt Challenge — `GET /comments?postId={id}`.
///
/// Sama seperti [Post], `fromJson`-nya dibuat aman terhadap field yang
/// hilang supaya perubahan skema di sisi server tidak membuat crash.
class Comment {
  const Comment({
    required this.postId,
    required this.id,
    required this.name,
    required this.email,
    required this.body,
  });

  final int postId;
  final int id;
  final String name;
  final String email;
  final String body;

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      postId: asInt(json['postId']),
      id: asInt(json['id']),
      name: asString(json['name']),
      email: asString(json['email']),
      body: asString(json['body']),
    );
  }

  Map<String, dynamic> toJson() => {
        'postId': postId,
        'id': id,
        'name': name,
        'email': email,
        'body': body,
      };

  @override
  String toString() => 'Comment(id: $id, postId: $postId, name: "$name")';
}
