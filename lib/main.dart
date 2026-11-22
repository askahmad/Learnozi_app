import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/theme_service.dart';
import 'services/user_service.dart';
import 'utils/app_theme.dart';

void main() async {
  // Ensure Flutter engine bindings are initialized before async Firebase call
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with options for multi-platform support (Android + Web)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  runApp(const LearnoziApp());
}

class LearnoziApp extends StatelessWidget {
  const LearnoziApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ThemeService(), UserService()]),
      builder: (context, _) {
        final isUrdu = UserService().profile.language == 'Urdu';
        return MaterialApp(
          title: isUrdu ? 'لرنوزی' : 'Learnozi',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeService().themeMode,
          locale: isUrdu ? const Locale('ur', 'PK') : const Locale('en', 'US'),
          home: const SplashScreen(),
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return ListenableBuilder(
      listenable: authService,
      builder: (context, _) {
        if (authService.isDemoActive) {
          return const HomeScreen();
        }

        return StreamBuilder<User?>(
          stream: authService.authStateChanges,
          builder: (context, snapshot) {
            // If checking authentication state, show loading spinner
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // If user is logged in, show HomeScreen
            if (snapshot.hasData && snapshot.data != null) {
              return const HomeScreen();
            }

            // Otherwise show LoginScreen
            return const LoginScreen();
          },
        );
      },
    );
  }
}
