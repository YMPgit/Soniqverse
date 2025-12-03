import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SoniqverseApp());
}

class SoniqverseApp extends StatelessWidget {
  const SoniqverseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soniqverse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          elevation: 0,
        ),
        sliderTheme: const SliderThemeData(
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
