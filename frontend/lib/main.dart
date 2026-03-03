import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'controllers/auth_controller.dart';
import 'controllers/todo_controller.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/reminder_screen.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'services/api_service.dart';
import 'middleware/auth_middleware.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ApiService());
    Get.lazyPut(() => AuthController());
    Get.lazyPut(() => TodoController());
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final notificationService = NotificationService();
  await notificationService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Todo App',
      debugShowCheckedModeBanner: false,
      initialBinding: AppBinding(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
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
      getPages: [
        GetPage(name: '/auth', page: () => const AuthScreen()),
        GetPage(
          name: '/home',
          page: () => const HomeScreen(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
          name: '/reminder',
          page: () => ReminderScreen(),
          middlewares: [AuthMiddleware()],
        ),
      ],
    );
  }
}
