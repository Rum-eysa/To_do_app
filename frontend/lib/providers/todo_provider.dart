import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../services/api_service.dart';

class TodoProvider with ChangeNotifier {
  List<Todo> _todos = [];
  bool _isLoading = false;
  String _filter = 'all';

  List<Todo> get todos {
    switch (_filter) {
      case 'active':
        return _todos.where((todo) => !todo.completed).toList();
      case 'completed':
        return _todos.where((todo) => todo.completed).toList();
      default:
        return _todos;
    }
  }

  bool get isLoading => _isLoading;
  String get filter => _filter;

  final ApiService _apiService = ApiService();

  Future<void> fetchTodos() async {
    _isLoading = true;
    notifyListeners();
    final todosData = await _apiService.getTodos();
    if (todosData != null) {
      // ÇÖZÜM: fromJson yerine fromMap kullanıyoruz
      _todos = todosData.map((todo) => Todo.fromMap(todo)).toList();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addTodo(String title, String description, String priority,
      DateTime? dueDate) async {
    if (dueDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final selectedDate = DateTime(dueDate.year, dueDate.month, dueDate.day);

      if (selectedDate.isBefore(today)) {
        return false;
      }
    }

    final todoData = await _apiService.createTodo({
      'title': title,
      'description': description,
      'priority': priority,
      'createdAt': DateTime.now().toIso8601String(), // Hibrit yapı için ekledik
      if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
    });

    if (todoData != null) {
      // ÇÖZÜM: fromJson yerine fromMap kullanıyoruz
      _todos.insert(0, Todo.fromMap(todoData));
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> updateTodo(String id, String title, String description,
      String priority, DateTime? dueDate) async {
    final todoData = await _apiService.updateTodo(id, {
      'title': title,
      'description': description,
      'priority': priority,
      'updatedAt': DateTime.now().toIso8601String(), // Güncelleme zamanı
      if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
    });

    if (todoData != null) {
      final index = _todos.indexWhere((todo) => todo.id == id);
      if (index != -1) {
        // ÇÖZÜM: fromJson yerine fromMap kullanıyoruz
        _todos[index] = Todo.fromMap(todoData);
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  Future<bool> toggleTodo(String id) async {
    final success = await _apiService.toggleTodo(id);
    if (success) {
      final index = _todos.indexWhere((todo) => todo.id == id);
      if (index != -1) {
        _todos[index].completed = !_todos[index].completed;
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  Future<bool> deleteTodo(String id) async {
    final success = await _apiService.deleteTodo(id);
    if (success) {
      _todos.removeWhere((todo) => todo.id == id);
      notifyListeners();
      return true;
    }
    return false;
  }

  void setFilter(String filter) {
    _filter = filter;
    notifyListeners();
  }

  int get activeTodoCount => _todos.where((todo) => !todo.completed).length;
}
