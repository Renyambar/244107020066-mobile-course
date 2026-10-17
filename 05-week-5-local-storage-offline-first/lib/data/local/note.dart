/// Langkah 1 (Model catatan) — codelab Minggu 5.
///
/// Field `dirty` menandai catatan yang **belum tersinkron** ke "server"
/// (dalam codelab ini server disimulasikan dengan delay). Field inilah yang
/// menjadi isi antrean sinkronisasi offline-first.
class Note {
  const Note({
    this.id,
    required this.title,
    this.body = '',
    required this.updatedAt,
    this.dirty = false,
  });

  /// `null` untuk catatan yang belum masuk database (belum punya baris).
  final int? id;

  final String title;
  final String body;

  /// Dipakai untuk pengurutan (`updated_at DESC`) **dan** sebagai penentu
  /// konflik sinkronisasi: *last-write-wins*.
  final DateTime updatedAt;

  /// `true` = perubahan lokal ini belum terkirim ke server.
  final bool dirty;

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'body': body,
        'updated_at': updatedAt.toIso8601String(),
        'dirty': dirty ? 1 : 0,
      };

  factory Note.fromMap(Map<String, Object?> map) {
    return Note(
      id: (map['id'] as num?)?.toInt(),
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      dirty: ((map['dirty'] as num?)?.toInt() ?? 0) == 1,
    );
  }

  Note copyWith({
    String? title,
    String? body,
    DateTime? updatedAt,
    bool? dirty,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      updatedAt: updatedAt ?? this.updatedAt,
      dirty: dirty ?? this.dirty,
    );
  }

  /// Aturan konflik sinkronisasi: **last-write-wins** berdasarkan
  /// [updatedAt] — catatan dengan timestamp terbaru yang menang.
  bool winsOver(Note other) => updatedAt.isAfter(other.updatedAt);

  String get syncLabel => dirty ? 'Belum tersinkron' : 'Tersinkron';

  @override
  String toString() =>
      'Note(id: $id, title: $title, updatedAt: $updatedAt, dirty: $dirty)';
}
