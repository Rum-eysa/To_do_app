import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart'
    hide AuthProvider; // Firebase'in AuthProvider'ını gizle
import 'providers/auth_provider.dart';
import 'providers/todo_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await dotenv.load();

  final notificationService = NotificationService();
  await notificationService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TodoProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            title: 'Todo App',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              useMaterial3: true,
            ),
            // --- GÜNCELLENEN OTOMATİK GİRİŞ MANTIĞI ---
            home: StreamBuilder<User?>(
              // Doğrudan Firebase'in oturum akışını dinliyoruz
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                // Eğer Firebase henüz cevap vermediyse yükleme ekranı göster
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                // Eğer snapshot.hasData true ise, kullanıcı içerde demektir
                if (snapshot.hasData) {
                  return const HomeScreen();
                }

                // Kullanıcı yoksa veya çıkış yapmışsa giriş ekranına gönder
                return const AuthScreen();
              },
            ),
            // --- OTOMATİK GİRİŞ MANTIĞI BİTTİ ---
          );
        },
      ),
    );
  }
}
