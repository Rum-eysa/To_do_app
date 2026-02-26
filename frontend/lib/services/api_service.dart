import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  // Web için localhost, Android emülatör için 10.0.2.2
  static const String _baseUrl = 'http://localhost:5000/api';

  // Her seferinde Firebase'den taze token al
  Future<Map<String, String>> _getHeaders() async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await user.getIdToken(); // ← her seferinde taze token
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // --- TODO ROTALARI ---

  Future<List<dynamic>?> getTodos() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/todos'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      print('getTodos hata: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      print('getTodos exception: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> createTodo(
      Map<String, dynamic> todoData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/todos'),
        headers: await _getHeaders(),
        body: jsonEncode(todoData),
      );
      if (response.statusCode == 201) return jsonDecode(response.body);
      print('createTodo hata: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      print('createTodo exception: $e');
      return null;
    }
  }

  Future<bool> toggleTodo(String id) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/todos/$id/toggle'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('toggleTodo exception: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> updateTodo(
      String id, Map<String, dynamic> todoData) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/todos/$id'),
        headers: await _getHeaders(),
        body: jsonEncode(todoData),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      print('updateTodo hata: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      print('updateTodo exception: $e');
      return null;
    }
  }

  Future<bool> deleteTodo(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/todos/$id'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('deleteTodo exception: $e');
      return false;
    }
  }
}
