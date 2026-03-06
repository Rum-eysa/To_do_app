import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';
import '../services/api_service.dart';
import '../utils/error_handler.dart';
import 'todo_controller.dart';

class AuthController extends GetxController {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  late final ApiService _apiService;

  final isLoading = false.obs;
  final error = RxnString();
  final currentUser = Rxn<User>();

  bool get isAuthenticated => currentUser.value != null;

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();

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
    loadUser();
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
      return await _apiService.syncUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        username: firebaseUser.displayName ?? 'Kullanıcı',
        idToken: idToken,
      );
    } catch (e) {
      return true;
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
      if (firebaseUser == null) {
        throw Exception('Firebase kullanıcısı alınamadı');
      }
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
      ErrorHandler.handle(e);
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
      if (firebaseUser == null) {
        throw Exception('Firebase kullanıcısı alınamadı');
      }
      await firebaseUser.updateDisplayName(username);
      await firebaseUser.reload();
      final updatedUser = _auth.currentUser!;
      await _syncWithBackend(updatedUser);
      final String? idToken = await updatedUser.getIdToken(true);
      currentUser.value = User(
        id: updatedUser.uid,
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
      ErrorHandler.handle(e);
      isLoading.value = false;
      return false;
    }
  }

  Future<void> logout() async {
    Get.find<TodoController>().clearTodos();
    await _auth.signOut();
    currentUser.value = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    Get.offAllNamed('/auth');
  }

  Future<void> _saveUserToLocal(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', json.encode(userData));
  }
}
