import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  // Sürdürülebilir JWT Akışı [cite: 2026-02-11]
  Stream<fb_auth.User?> get userStatusStream =>
      fb_auth.FirebaseAuth.instance.authStateChanges();

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      final userCredential = await fb_auth.FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // JWT Alımı [cite: 2026-02-11]
      final String? jwtToken = await userCredential.user?.getIdToken();

      if (userCredential.user != null) {
        _currentUser = User(
          id: userCredential.user!.uid,
          email: userCredential.user!.email ?? "",
          username: userCredential.user!.displayName ?? "Kullanıcı",
        );

        await _saveUserToLocal({
          'id': _currentUser!.id,
          'email': _currentUser!.email,
          'token': jwtToken, // JWT saklanıyor [cite: 2026-02-11]
        });

        _setLoading(false);
        return true;
      }
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
    return false;
  }

  Future<bool> register(String username, String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      final userCredential = await fb_auth.FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await userCredential.user?.updateDisplayName(username);

      if (userCredential.user != null) {
        _currentUser = User(
          id: userCredential.user!.uid,
          email: email,
          username: username,
        );
        _setLoading(false);
        return true;
      }
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
    return false;
  }

  Future<void> logout() async {
    await fb_auth.FirebaseAuth.instance.signOut();
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
