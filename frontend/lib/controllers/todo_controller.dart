import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/todo.dart';
import '../utils/error_handler.dart';

class TodoController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final todos = <Todo>[].obs;
  final isLoading = false.obs;
  final filter = 'all'.obs;

  List<Todo> get filteredTodos {
    switch (filter.value) {
      case 'active':
        return todos.where((t) => !t.completed).toList();
      case 'completed':
        return todos.where((t) => t.completed).toList();
      default:
        return todos;
    }
  }

  int get activeTodoCount => todos.where((t) => !t.completed).length;

  CollectionReference? get _todosRef {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('todos');
  }

  @override
  void onInit() {
    super.onInit();
    fetchTodos();
  }

  Future<void> fetchTodos() async {
    isLoading.value = true;
    try {
      await _loadFromCache();
      final ref = _todosRef;
      if (ref == null) return;
      final snapshot = await ref.orderBy('createdAt', descending: true).get();
      todos.value =
          snapshot.docs.map((doc) => Todo.fromFirestore(doc)).toList();
      await _saveToCache();
    } catch (e) {
      ErrorHandler.handle(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addTodo(String title, String description, String priority,
      DateTime? dueDate) async {
    if (dueDate != null) {
      final today = DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day);
      final selected = DateTime(dueDate.year, dueDate.month, dueDate.day);
      if (selected.isBefore(today)) return false;
    }

    try {
      final ref = _todosRef;
      if (ref == null) return false;

      final data = {
        'title': title,
        'description': description,
        'priority': priority,
        'completed': false,
        'createdAt': FieldValue.serverTimestamp(),
        if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
      };

      final docRef = await ref.add(data);

      todos.insert(
          0,
          Todo(
            id: docRef.id,
            title: title,
            description: description,
            priority: priority,
            completed: false,
            dueDate: dueDate,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isSynced: true,
          ));

      await _saveToCache();
      return true;
    } catch (e) {
      ErrorHandler.handle(e);
      return false;
    }
  }

  Future<bool> updateTodo(String id, String title, String description,
      String priority, DateTime? dueDate) async {
    try {
      final ref = _todosRef;
      if (ref == null) return false;

      await ref.doc(id).update({
        'title': title,
        'description': description,
        'priority': priority,
        if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final index = todos.indexWhere((t) => t.id == id);
      if (index != -1) {
        todos[index] = Todo(
          id: id,
          title: title,
          description: description,
          priority: priority,
          completed: todos[index].completed,
          dueDate: dueDate,
          createdAt: todos[index].createdAt,
          updatedAt: DateTime.now(),
          isSynced: true,
        );
        await _saveToCache();
      }
      return true;
    } catch (e) {
      ErrorHandler.handle(e);
      return false;
    }
  }

  Future<bool> toggleTodo(String id) async {
    try {
      final ref = _todosRef;
      if (ref == null) return false;

      final index = todos.indexWhere((t) => t.id == id);
      if (index == -1) return false;

      final newCompleted = !todos[index].completed;
      await ref.doc(id).update({'completed': newCompleted});

      todos[index] = Todo(
        id: todos[index].id,
        title: todos[index].title,
        description: todos[index].description,
        priority: todos[index].priority,
        completed: newCompleted,
        dueDate: todos[index].dueDate,
        createdAt: todos[index].createdAt,
        updatedAt: DateTime.now(),
        isSynced: true,
      );

      await _saveToCache();
      return true;
    } catch (e) {
      ErrorHandler.handle(e);
      return false;
    }
  }

  Future<bool> deleteTodo(String id) async {
    try {
      final ref = _todosRef;
      if (ref == null) return false;

      await ref.doc(id).delete();
      todos.removeWhere((t) => t.id == id);
      await _saveToCache();
      return true;
    } catch (e) {
      ErrorHandler.handle(e);
      return false;
    }
  }

  void setFilter(String value) {
    filter.value = value;
  }

  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = todos.map((t) => t.toMap()).toList();
      await prefs.setString('todos_cache', json.encode(data));
    } catch (e) {
      ErrorHandler.handle(e);
    }
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('todos_cache');
      if (cached != null) {
        final list = json.decode(cached) as List;
        todos.value = list.map((e) => Todo.fromMap(e)).toList();
      }
    } catch (e) {
      ErrorHandler.handle(e);
    }
  }
}
