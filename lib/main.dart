import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/connect_screen.dart';
import 'screens/generator_screen.dart';
import 'screens/workspace_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/archived_ideas_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const ReelMindApp());
}

class ReelMindApp extends StatelessWidget {
  const ReelMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reel Mind',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/': (context) => const HomeScreen(),
        '/connect': (context) => const ConnectScreen(),
        '/generator': (context) => const GeneratorScreen(),
        '/workspace': (context) => const WorkspaceScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/archived': (context) => const ArchivedIdeasScreen(),
      },
    );
  }
}
