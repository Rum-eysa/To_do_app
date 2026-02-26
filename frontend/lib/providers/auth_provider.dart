import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:http/http.dart' as http;
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Android emülatör için 10.0.2.2, gerçek cihaz için kendi IP'ni yaz
  static const String _baseUrl = 'http://10.0.2.2:3000/api';

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  Stream<fb_auth.User?> get userStatusStream => _auth.authStateChanges();

  // Uygulama açılınca kayıtlı oturumu yükle
  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      final map = json.decode(userData);
      _currentUser = User(
        id: map['id'],
        email: map['email'],
        username: map['username'] ?? 'Kullanıcı',
      );
      notifyListeners();
    }
  }

  // Backend'e Firebase idToken gönderen ortak metod
  Future<bool> _syncWithBackend(fb_auth.User firebaseUser) async {
    try {
      final String? idToken = await firebaseUser.getIdToken();
      if (idToken == null) return false;

      final response = await http.post(
        Uri.parse('$_baseUrl/auth'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'uid': firebaseUser.uid,
          'email': firebaseUser.email,
          'username': firebaseUser.displayName ?? 'Kullanıcı',
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      _error = 'Backend bağlantı hatası: $e';
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null)
        throw Exception('Firebase kullanıcısı alınamadı');

      // Backend ile senkronize et
      final backendSuccess = await _syncWithBackend(firebaseUser);
      if (!backendSuccess) throw Exception('Backend doğrulaması başarısız');

      final String? idToken = await firebaseUser.getIdToken();

      _currentUser = User(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        username: firebaseUser.displayName ?? 'Kullanıcı',
      );

      await _saveUserToLocal({
        'id': _currentUser!.id,
        'email': _currentUser!.email,
        'username': _currentUser!.username,
        'token': idToken,
      });

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register(String username, String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null)
        throw Exception('Firebase kullanıcısı alınamadı');

      // Display name güncelle
      await firebaseUser.updateDisplayName(username);
      await firebaseUser.reload(); // Güncellemenin yansıması için

      // Backend ile senkronize et (register'da da şart!)
      final backendSuccess = await _syncWithBackend(firebaseUser);
      if (!backendSuccess) throw Exception('Backend kaydı başarısız');

      final String? idToken = await firebaseUser.getIdToken();

      _currentUser = User(
        id: firebaseUser.uid,
        email: email,
        username: username,
      );

      await _saveUserToLocal({
        'id': _currentUser!.id,
        'email': _currentUser!.email,
        'username': username,
        'token': idToken,
      });

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    notifyListeners();
  }

  Future<void> _saveUserToLocal(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', json.encode(userData));
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
