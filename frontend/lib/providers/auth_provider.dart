import 'package:flutter/material.dart';
import 'dart:convert'; // JSON işlemleri için gerekli
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  final ApiService _apiService = ApiService();

  // --- YENİ: OTOMATİK GİRİŞ KONTROLÜ ---
  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('user_data')) return;

    final String? savedData = prefs.getString('user_data');
    if (savedData != null) {
      _currentUser = User.fromJson(json.decode(savedData));
      notifyListeners();
    }
  }

  Future<bool> register(String username, String email, String password) async {
    _setLoading(true);
    _clearError();
    final userData = await _apiService.register(username, email, password);
    if (userData != null) {
      _currentUser = User.fromJson(userData);

      // Kayıt başarılıysa veriyi hafızaya kaydet
      await _saveUserToLocal(userData);

      _setLoading(false);
      return true;
    }
    _error = 'Registration failed';
    _setLoading(false);
    return false;
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();
    final userData = await _apiService.login(email, password);
    if (userData != null) {
      _currentUser = User.fromJson(userData);

      // Giriş başarılıysa veriyi hafızaya kaydet
      await _saveUserToLocal(userData);

      _setLoading(false);
      return true;
    }
    _error = 'Login failed';
    _setLoading(false);
    return false;
  }

  Future<void> logout() async {
    await _apiService.logout();
    _currentUser = null;

    // Çıkış yapınca hafızadaki veriyi sil
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');

    notifyListeners();
  }

  // --- YARDIMCI METODLAR ---
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
