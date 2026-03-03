import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'controllers/auth_controller.dart';
import 'controllers/todo_controller.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Notification servisini başlat (Instance üzerinden çağırmak daha güvenlidir)
  final notificationService = NotificationService();
  await notificationService.init();

  // Controller'ları lazyPut veya put ile başlatıyoruz
  Get.put(AuthController());
  Get.put(TodoController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // Burada fazladan bir parantez ve boşluk vardı, düzeltildi.
      title: 'Todo App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),

      // Auth durumuna göre ana ekranı belirleyen yapı
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          return const AuthScreen();
        },
      ),

      // GetX route tanımlamaları
      getPages: [
        GetPage(name: '/auth', page: () => const AuthScreen()),
        GetPage(name: '/home', page: () => const HomeScreen()),
      ],
    );
  }
}
