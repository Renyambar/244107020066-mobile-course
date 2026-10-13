import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/todo.dart';

/// Enum filter status ToDo
enum TodoFilter {
  all,
  active,
  completed,
}

/// Notifier untuk mengelola filter aktif
class TodoFilterNotifier extends Notifier<TodoFilter> {
  @override
  TodoFilter build() => TodoFilter.all;

  void setFilter(TodoFilter filter) {
    state = filter;
  }
}

/// Provider untuk filter yang dipilih user
final todoFilterProvider =
    NotifierProvider<TodoFilterNotifier, TodoFilter>(TodoFilterNotifier.new);

/// Notifier untuk state daftar tugas ToDo secara immutable
class TodoListNotifier extends Notifier<List<Todo>> {
  @override
  List<Todo> build() {
    // Memberikan data awal agar aplikasi langsung memiliki item contoh
    return const [
      Todo(id: '1', title: 'Mempelajari Navigasi GoRouter', done: true),
      Todo(id: '2', title: 'Memahami State Management Riverpod', done: false),
      Todo(id: '3', title: 'Eksperimen AsyncValue & Error Handling', done: false),
    ];
  }

  /// Menambah tugas baru ke dalam state (Immutability: state baru dibuat)
  void add(String title) {
    final newTodo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      done: false,
    );
    state = [...state, newTodo];
  }

  /// Toggle status selesai ToDo berdasarkan ID
  void toggle(String id) {
    state = [
      for (final todo in state)
        if (todo.id == id) todo.copyWith(done: !todo.done) else todo,
    ];
  }

  /// Menghapus ToDo berdasarkan ID
  void remove(String id) {
    state = state.where((todo) => todo.id != id).toList();
  }

  /// Toggle status selesai ToDo berdasarkan index (kompatibilitas praktikum dasar)
  void toggleAt(int index) {
    if (index >= 0 && index < state.length) {
      final todos = [...state];
      todos[index] = todos[index].copyWith(done: !todos[index].done);
      state = todos;
    }
  }

  /// Menghapus ToDo berdasarkan index (kompatibilitas praktikum dasar)
  void removeAt(int index) {
    if (index >= 0 && index < state.length) {
      final todos = [...state]..removeAt(index);
      state = todos;
    }
  }
}

/// NotifierProvider global untuk daftar ToDo
final todoListProvider =
    NotifierProvider<TodoListNotifier, List<Todo>>(TodoListNotifier.new);

/// Provider turunan (derived provider) yang memfilter list sesuai todoFilterProvider
final filteredTodoListProvider = Provider<List<Todo>>((ref) {
  final filter = ref.watch(todoFilterProvider);
  final todos = ref.watch(todoListProvider);

  switch (filter) {
    case TodoFilter.all:
      return todos;
    case TodoFilter.active:
      return todos.where((todo) => !todo.done).toList();
    case TodoFilter.completed:
      return todos.where((todo) => todo.done).toList();
  }
});
