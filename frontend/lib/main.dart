import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() => runApp(const EcoEatApp());

class EcoEatApp extends StatelessWidget {
  const EcoEatApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF287A4B);
    return MaterialApp(
      title: 'EcoEat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(filled: true),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
