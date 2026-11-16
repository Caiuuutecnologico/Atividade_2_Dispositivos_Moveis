import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF102A43);
    return MaterialApp(
      title: 'Tempo por aqui',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF167D8D)),
        scaffoldBackgroundColor: const Color(0xFFF3F7F8),
        appBarTheme: const AppBarTheme(
            backgroundColor: navy, foregroundColor: Colors.white),
        cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20))),
      ),
      home: const HomeScreen(),
    );
  }
}
