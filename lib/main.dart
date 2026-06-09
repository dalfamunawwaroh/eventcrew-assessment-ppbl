import 'package:flutter/material.dart';
import 'helpers/prefs_helper.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/landing_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PrefsHelper.init();
  runApp(const EventCrewApp());
}

class EventCrewApp extends StatelessWidget {
  const EventCrewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EventCrew',
      debugShowCheckedModeBanner: false,
      themeMode: PrefsHelper.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF4F7FC),
        primaryColor: const Color(0xFF1E3A8A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF1E3A8A),
          secondary: const Color(0xFF10B981),
        ),
      ),
      // Show SplashScreen first (3-sec timer) → LandingPage → HomeScreen
      home: const SplashScreen(),
    );
  }
}