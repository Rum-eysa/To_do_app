import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user.dart';

class AuthController extends GetxController {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;

  static const String _baseUrl = 'http://10.0.2.2:5000/api';

  // Observable değişkenler
  final isLoading = false.obs;
  final error = RxnString();
  final currentUser = Rxn<User>(); // null olabilir

  // Getter'lar
  bool get isAuthenticated => currentUser.value != null;

  @override
  void onInit() {
    super.onInit();
    // Firebase auth durumunu dinle
    _auth.authStateChanges().listen((fbUser) {
      if (fbUser == null) {
        currentUser.value = null;
      } else {
        currentUser.value = User(
          id: fbUser.uid,
          email: fbUser.email ?? '',
          username: fbUser.displayName ?? 'Kullanıcı',
        );
      }
    });
    loadUser(); // Cache'den yükle
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      final map = json.decode(userData);
      currentUser.value = User(
        id: map['id'],
        email: map['email'],
        username: map['username'] ?? 'Kullanıcı',
      );
    }
  }

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
      return true; // Backend hatası login'i engellemesin
    }
  }

  Future<bool> login(String email, String password) async {
    isLoading.value = true;
    error.value = null;

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null)
        throw Exception('Firebase kullanıcısı alınamadı');

      await _syncWithBackend(firebaseUser);

      final String? idToken = await firebaseUser.getIdToken();

      currentUser.value = User(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        username: firebaseUser.displayName ?? 'Kullanıcı',
      );

      await _saveUserToLocal({
        'id': currentUser.value!.id,
        'email': currentUser.value!.email,
        'username': currentUser.value!.username,
        'token': idToken,
      });

      isLoading.value = false;
      return true;
    } catch (e) {
      error.value = e.toString();
      isLoading.value = false;
      return false;
    }
  }

  Future<bool> register(String username, String email, String password) async {
    isLoading.value = true;
    error.value = null;

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null)
        throw Exception('Firebase kullanıcısı alınamadı');

      await firebaseUser.updateDisplayName(username);
      await firebaseUser.reload();

      await _syncWithBackend(firebaseUser);

      final String? idToken = await firebaseUser.getIdToken();

      currentUser.value = User(
        id: firebaseUser.uid,
        email: email,
        username: username,
      );

      await _saveUserToLocal({
        'id': currentUser.value!.id,
        'email': currentUser.value!.email,
        'username': username,
        'token': idToken,
      });

      isLoading.value = false;
      return true;
    } catch (e) {
      error.value = e.toString();
      isLoading.value = false;
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    currentUser.value = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    Get.offAllNamed('/auth'); // ← GetX navigation
  }

  Future<void> _saveUserToLocal(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', json.encode(userData));
  }
}
