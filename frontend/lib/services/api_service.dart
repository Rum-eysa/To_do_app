import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // 10.0.2.2 yerine bilgisayarının IP adresini yazmalısın (Örn: 192.168.1.35)
  // Eğer .env dosyasında API_URL tanımlıysa orayı da güncellemelisin.
  static final String _baseUrl = dotenv.env['API_URL'] ??
      'http://192.168.10.192:5000/api'; // <--- BURAYI DEĞİŞTİR

  Future<Map<String, String>> _getHeaders({bool authRequired = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    };
    if (authRequired) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // --- AUTH ROTALARI ---

  Future<Map<String, dynamic>?> register(
      String username, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: await _getHeaders(authRequired: false),
        body: jsonEncode(
            {'username': username, 'email': email, 'password': password}),
      );
      if (response.statusCode == 201) return jsonDecode(response.body);
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: await _getHeaders(authRequired: false),
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) await saveToken(data['token']);
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Provider'ın beklediği logout metodu
  Future<void> logout() async {
    await removeToken();
  }

  // --- TODO ROTALARI ---

  Future<List<dynamic>?> getTodos() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/todos'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200 ? jsonDecode(response.body) : null;
    } catch (e) {
      return null;
    }
  }

  // Provider'ın beklediği createTodo metodu
  Future<Map<String, dynamic>?> createTodo(
      Map<String, dynamic> todoData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/todos'),
        headers: await _getHeaders(),
        body: jsonEncode(todoData),
      );
      return response.statusCode == 201 ? jsonDecode(response.body) : null;
    } catch (e) {
      return null;
    }
  }

  // Provider'ın beklediği toggleTodo metodu
  Future<bool> toggleTodo(String id) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/todos/$id/toggle'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
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
      return response.statusCode == 200 ? jsonDecode(response.body) : null;
    } catch (e) {
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
      return false;
    }
  }
}
