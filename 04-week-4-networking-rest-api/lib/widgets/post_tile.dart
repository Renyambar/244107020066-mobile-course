import 'package:flutter/material.dart';

import '../data/models/post.dart';

/// Refactoring Challenge #1 — widget baris post dipisah dari ListView.builder
/// menjadi widget tersendiri agar halaman menjadi ringkas dan widget ini
/// bisa diuji secara terisolasi (widget test).
class PostTile extends StatelessWidget {
  const PostTile({
    super.key,
    required this.post,
    this.onTap,
    this.showBody = true,
  });

  final Post post;
  final VoidCallback? onTap;

  /// Halaman paginated hanya menampilkan judul, halaman penuh menampilkan
  /// judul + isi ringkasan.
  final bool showBody;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(child: Text(post.id.toString())),
      title: Text(
        post.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: showBody
          ? Text(
              post.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          : null,
    );
  }
}
