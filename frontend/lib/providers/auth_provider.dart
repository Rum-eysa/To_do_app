import 'package:flutter/material.dart';
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

  Future<bool> register(String username, String email, String password) async {
    _setLoading(true);
    _clearError();
    final userData = await _apiService.register(username, email, password);
    if (userData != null) {
      _currentUser = User.fromJson(userData);
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
    notifyListeners();
  }

  void _setLoading(bool value) { _isLoading = value; notifyListeners(); }
  void _clearError() { _error = null; notifyListeners(); }
}
