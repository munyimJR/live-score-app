import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'services/match_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Auto-seed sample matches if collection is empty
  await MatchService().autoSeedIfEmpty();

  runApp(const LiveScoreApp());
}

class LiveScoreApp extends StatelessWidget {
  const LiveScoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Cricket Live Score',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 280),
      home: const HomeScreen(),
    );
  }
}
