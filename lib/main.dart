import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// 🌈 Importation du thème global
import 'pages/theme.dart';

// 🧩 Importation des pages
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/user_profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Erreur Firebase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SafeZone',

      // 🎨 Application du thème global depuis theme.dart
      theme: appTheme,

      // 🧭 Routes
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/user': (context) => const UserProfilePage(),
        // Tu pourras ajouter ici d'autres pages : /map, /alert, etc.
      },
    );
  }
}
