import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/todo.dart';

class TodoProvider with ChangeNotifier {
  List<Todo> _todos = [];
  bool _isLoading = false;
  String _filter = 'all';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Todo> get todos {
    switch (_filter) {
      case 'active':
        return _todos.where((t) => !t.completed).toList();
      case 'completed':
        return _todos.where((t) => t.completed).toList();
      default:
        return _todos;
    }
  }

  bool get isLoading => _isLoading;
  String get filter => _filter;
  int get activeTodoCount => _todos.where((t) => !t.completed).length;

  // Kullanıcının Firestore koleksiyonu
  CollectionReference? get _todosRef {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('todos');
  }

  // Firestore'dan çek + yerel cache'e kaydet
  Future<void> fetchTodos() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Önce cache'den yükle (hızlı görünüm)
      await _loadFromCache();

      // Sonra Firestore'dan güncelle
      final ref = _todosRef;
      if (ref == null) return;

      final snapshot = await ref.orderBy('createdAt', descending: true).get();
      _todos = snapshot.docs.map((doc) => Todo.fromFirestore(doc)).toList();

      // Cache'i güncelle
      await _saveToCache();
    } catch (e) {
      print('fetchTodos error: $e');
      // Hata olursa cache'deki veri kalır
    } finally {
      _isLoading = false;
      notifyListeners();
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

      // Listeye ekle
      _todos.insert(
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
      notifyListeners();
      return true;
    } catch (e) {
      print('addTodo error: $e');
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

      final index = _todos.indexWhere((t) => t.id == id);
      if (index != -1) {
        _todos[index] = Todo(
          id: id,
          title: title,
          description: description,
          priority: priority,
          completed: _todos[index].completed,
          dueDate: dueDate,
          createdAt: _todos[index].createdAt,
          updatedAt: DateTime.now(),
          isSynced: true,
        );
        await _saveToCache();
        notifyListeners();
      }
      return true;
    } catch (e) {
      print('updateTodo error: $e');
      return false;
    }
  }

  Future<bool> toggleTodo(String id) async {
    try {
      final ref = _todosRef;
      if (ref == null) return false;

      final index = _todos.indexWhere((t) => t.id == id);
      if (index == -1) return false;

      final newCompleted = !_todos[index].completed;
      await ref.doc(id).update({'completed': newCompleted});

      _todos[index].completed = newCompleted;
      await _saveToCache();
      notifyListeners();
      return true;
    } catch (e) {
      print('toggleTodo error: $e');
      return false;
    }
  }

  Future<bool> deleteTodo(String id) async {
    try {
      final ref = _todosRef;
      if (ref == null) return false;

      await ref.doc(id).delete();
      _todos.removeWhere((t) => t.id == id);
      await _saveToCache();
      notifyListeners();
      return true;
    } catch (e) {
      print('deleteTodo error: $e');
      return false;
    }
  }

  void setFilter(String filter) {
    _filter = filter;
    notifyListeners();
  }

  // Cache işlemleri
  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _todos.map((t) => t.toMap()).toList();
      await prefs.setString('todos_cache', json.encode(data));
    } catch (e) {
      print('Cache kaydetme hatası: $e');
    }
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('todos_cache');
      if (cached != null) {
        final list = json.decode(cached) as List;
        _todos = list.map((e) => Todo.fromMap(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      print('Cache yükleme hatası: $e');
    }
  }
}
