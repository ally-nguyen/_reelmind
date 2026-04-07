import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
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
import 'screens/survey_topics_screen.dart';
import 'screens/survey_captions_screen.dart';
import 'screens/survey_creators_screen.dart';
import 'screens/survey_videos_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
          return const LoginScreen();
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomeScreen(),
        '/connect': (context) => const ConnectScreen(),
        '/generator': (context) => const GeneratorScreen(),
        '/workspace': (context) => const WorkspaceScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/archived': (context) => const ArchivedIdeasScreen(),
        '/survey/topics': (context) => const SurveyTopicsScreen(),
        '/survey/captions': (context) => const SurveyCaptionsScreen(),
        '/survey/creators': (context) => const SurveyCreatorsScreen(),
        '/survey/videos': (context) => const SurveyVideosScreen(),
      },
    );
  }
}
