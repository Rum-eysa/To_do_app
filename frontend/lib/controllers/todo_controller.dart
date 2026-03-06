import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/todo.dart';
import '../services/database_service.dart';
import '../utils/error_handler.dart';
import 'package:uuid/uuid.dart';

class TodoController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _db = DatabaseService.instance;

  final todos = <Todo>[].obs;
  final isLoading = false.obs;
  final filter = 'all'.obs;
  final isSyncing = false.obs;

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

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference? get _todosRef {
    final uid = _userId;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('todos');
  }

  Future<bool> get _isOnline async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  @override
  void onInit() {
    super.onInit();
    fetchTodos();

    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        debugPrint('🔄 Bağlantı geldi, senkronize ediliyor...');
        syncToFirebase();
      }
    });
  }

  Future<void> fetchTodos() async {
    final uid = _userId;
    if (uid == null) return;

    isLoading.value = true;
    try {
      final localTodos = await _db.getAllTodos(uid);
      debugPrint('📦 SQLite todo sayısı: ${localTodos.length}');
      todos.value = localTodos;

      if (await _isOnline) {
        debugPrint('🌐 Online - Firebase\'den yükleniyor...');
        await _fetchFromFirebase();
      } else {
        debugPrint('📴 Offline - sadece SQLite kullanılıyor');
      }
    } catch (e) {
      debugPrint('❌ fetchTodos error: $e');
      ErrorHandler.handle(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchFromFirebase() async {
    final uid = _userId;
    if (uid == null) return;

    try {
      final ref = _todosRef;
      if (ref == null) return;

      final snapshot = await ref.orderBy('createdAt', descending: true).get();
      final firebaseTodos =
          snapshot.docs.map((doc) => Todo.fromFirestore(doc)).toList();

      debugPrint('🔥 Firebase todo sayısı: ${firebaseTodos.length}');

      await _db.upsertTodos(firebaseTodos, uid);
      todos.value = await _db.getAllTodos(uid);

      debugPrint('✅ SQLite güncellendi: ${todos.length} todo');
    } catch (e) {
      debugPrint('❌ _fetchFromFirebase error: $e');
      ErrorHandler.handle(e);
    }
  }

  Future<bool> addTodo(String title, String description, String priority,
      DateTime? dueDate) async {
    final uid = _userId;
    if (uid == null) return false;

    if (dueDate != null) {
      final today = DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day);
      final selected = DateTime(dueDate.year, dueDate.month, dueDate.day);
      if (selected.isBefore(today)) return false;
    }

    try {
      final now = DateTime.now();
      final localId = const Uuid().v4();

      final todo = Todo(
        id: localId,
        title: title,
        description: description,
        priority: priority,
        completed: false,
        dueDate: dueDate,
        createdAt: now,
        updatedAt: now,
        isSynced: false,
      );

      await _db.insertTodo(todo, uid);
      debugPrint('💾 SQLite\'a eklendi: $localId');
      todos.insert(0, todo);

      if (await _isOnline) {
        debugPrint('🌐 Firebase\'e gönderiliyor...');
        await _syncTodoToFirebase(todo);
      } else {
        debugPrint('📴 Offline - sadece SQLite\'a kaydedildi');
      }

      return true;
    } catch (e) {
      debugPrint('❌ addTodo error: $e');
      ErrorHandler.handle(e);
      return false;
    }
  }

  Future<void> _syncTodoToFirebase(Todo todo) async {
    final uid = _userId;
    if (uid == null) return;

    try {
      final ref = _todosRef;
      if (ref == null) return;

      final data = {
        'title': todo.title,
        'description': todo.description,
        'priority': todo.priority,
        'completed': todo.completed,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (todo.dueDate != null) 'dueDate': todo.dueDate!.toIso8601String(),
      };

      final docRef = await ref.add(data);
      debugPrint('🔥 Firebase ID alındı: ${docRef.id}');

      await _db.deleteTodo(todo.id, uid);
      final syncedTodo = Todo(
        id: docRef.id,
        title: todo.title,
        description: todo.description,
        priority: todo.priority,
        completed: todo.completed,
        dueDate: todo.dueDate,
        createdAt: todo.createdAt,
        updatedAt: todo.updatedAt,
        isSynced: true,
      );
      await _db.insertTodo(syncedTodo, uid);
      debugPrint('✅ SQLite Firebase ID ile güncellendi: ${docRef.id}');

      final index = todos.indexWhere((t) => t.id == todo.id);
      if (index != -1) {
        todos[index] = syncedTodo;
      }
    } catch (e) {
      debugPrint('❌ _syncTodoToFirebase error: $e');
      ErrorHandler.handle(e);
    }
  }

  Future<bool> updateTodo(String id, String title, String description,
      String priority, DateTime? dueDate) async {
    final uid = _userId;
    if (uid == null) return false;

    try {
      final index = todos.indexWhere((t) => t.id == id);
      if (index == -1) return false;

      final updated = Todo(
        id: id,
        title: title,
        description: description,
        priority: priority,
        completed: todos[index].completed,
        dueDate: dueDate,
        createdAt: todos[index].createdAt,
        updatedAt: DateTime.now(),
        isSynced: false,
      );

      await _db.updateTodo(updated, uid);
      todos[index] = updated;

      if (await _isOnline) {
        final ref = _todosRef;
        if (ref != null) {
          await ref.doc(id).update({
            'title': title,
            'description': description,
            'priority': priority,
            if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          await _db.markAsSynced(id, uid);
          todos[index] = Todo(
            id: updated.id,
            title: updated.title,
            description: updated.description,
            priority: updated.priority,
            completed: updated.completed,
            dueDate: updated.dueDate,
            createdAt: updated.createdAt,
            updatedAt: updated.updatedAt,
            isSynced: true,
          );
        }
      }

      return true;
    } catch (e) {
      debugPrint('❌ updateTodo error: $e');
      ErrorHandler.handle(e);
      return false;
    }
  }

  Future<bool> toggleTodo(String id) async {
    final uid = _userId;
    if (uid == null) return false;

    try {
      final index = todos.indexWhere((t) => t.id == id);
      if (index == -1) return false;

      final newCompleted = !todos[index].completed;
      final updated = Todo(
        id: todos[index].id,
        title: todos[index].title,
        description: todos[index].description,
        priority: todos[index].priority,
        completed: newCompleted,
        dueDate: todos[index].dueDate,
        createdAt: todos[index].createdAt,
        updatedAt: DateTime.now(),
        isSynced: false,
      );

      await _db.updateTodo(updated, uid);
      todos[index] = updated;

      if (await _isOnline) {
        final ref = _todosRef;
        if (ref != null) {
          await ref.doc(id).update({
            'completed': newCompleted,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          await _db.markAsSynced(id, uid);
        }
      }

      return true;
    } catch (e) {
      debugPrint('❌ toggleTodo error: $e');
      ErrorHandler.handle(e);
      return false;
    }
  }

  Future<bool> deleteTodo(String id) async {
    final uid = _userId;
    if (uid == null) return false;

    try {
      await _db.deleteTodo(id, uid);
      todos.removeWhere((t) => t.id == id);

      if (await _isOnline) {
        final ref = _todosRef;
        if (ref != null) {
          await ref.doc(id).delete();
        }
      }

      return true;
    } catch (e) {
      debugPrint('❌ deleteTodo error: $e');
      ErrorHandler.handle(e);
      return false;
    }
  }

  Future<void> syncToFirebase() async {
    final uid = _userId;
    if (uid == null) return;
    if (isSyncing.value) return;
    isSyncing.value = true;

    try {
      final unsyncedTodos = await _db.getUnsyncedTodos(uid);
      debugPrint('🔄 Senkronize edilecek todo sayısı: ${unsyncedTodos.length}');
      if (unsyncedTodos.isEmpty) return;

      final ref = _todosRef;
      if (ref == null) return;

      for (final todo in unsyncedTodos) {
        try {
          final doc = await ref.doc(todo.id).get();
          if (doc.exists) {
            await ref.doc(todo.id).update({
              'title': todo.title,
              'description': todo.description,
              'priority': todo.priority,
              'completed': todo.completed,
              if (todo.dueDate != null)
                'dueDate': todo.dueDate!.toIso8601String(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } else {
            await _syncTodoToFirebase(todo);
          }
          await _db.markAsSynced(todo.id, uid);
        } catch (e) {
          debugPrint('❌ syncToFirebase item error: $e');
          ErrorHandler.handle(e);
        }
      }

      todos.value = await _db.getAllTodos(uid);
      debugPrint('✅ Senkronizasyon tamamlandı');
    } catch (e) {
      debugPrint('❌ syncToFirebase error: $e');
      ErrorHandler.handle(e);
    } finally {
      isSyncing.value = false;
    }
  }

  void clearTodos() {
    todos.clear();
  }

  void setFilter(String value) {
    filter.value = value;
  }
}
