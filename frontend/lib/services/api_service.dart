import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ApiService extends GetConnect {
  static const String _baseUrl = 'http://localhost:5000/api';

  Future<Map<String, String>> _getHeaders() async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<List<dynamic>?> getTodos() async {
    try {
      final response = await get(
        '$_baseUrl/todos',
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) return response.body;
      debugPrint('getTodos hata: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('getTodos exception: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> createTodo(
      Map<String, dynamic> todoData) async {
    try {
      final response = await post(
        '$_baseUrl/todos',
        todoData,
        headers: await _getHeaders(),
      );
      if (response.statusCode == 201) return response.body;
      debugPrint('createTodo hata: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('createTodo exception: $e');
      return null;
    }
  }

  Future<bool> toggleTodo(String id) async {
    try {
      final response = await patch(
        '$_baseUrl/todos/$id/toggle',
        {},
        headers: await _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('toggleTodo exception: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> updateTodo(
      String id, Map<String, dynamic> todoData) async {
    try {
      final response = await put(
        '$_baseUrl/todos/$id',
        todoData,
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) return response.body;
      debugPrint('updateTodo hata: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('updateTodo exception: $e');
      return null;
    }
  }

  Future<bool> deleteTodo(String id) async {
    try {
      final response = await delete(
        '$_baseUrl/todos/$id',
        headers: await _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('deleteTodo exception: $e');
      return false;
    }
  }

  Future<bool> syncUser({
    required String uid,
    required String email,
    required String username,
    required String idToken,
  }) async {
    try {
      final response = await post(
        '$_baseUrl/auth',
        {'uid': uid, 'email': email, 'username': username},
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return true;
    }
  }
}
