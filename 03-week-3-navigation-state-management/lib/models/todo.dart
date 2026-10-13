class Todo {
  final String id;
  final String title;
  final bool done;

  const Todo({
    required this.id,
    required this.title,
    this.done = false,
  });

  Todo copyWith({
    String? id,
    String? title,
    bool? done,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      done: done ?? this.done,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Todo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          done == other.done;

  @override
  int get hashCode => id.hashCode ^ title.hashCode ^ done.hashCode;
}
