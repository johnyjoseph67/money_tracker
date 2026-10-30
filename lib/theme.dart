import 'package:flutter/material.dart';

class C {
  static const navy = Color(0xFF0F172A);
  static const teal = Color(0xFF0F766E);
  static const mint = Color(0xFF14B8A6);
  static const paper = Color(0xFFF1F5F9);
  static const slate = Color(0xFF475569);
  static const orange = Color(0xFF9A3412);
  static const blue = Color(0xFF1E40AF);
  static const red = Color(0xFFB91C1C);
  static const green = Color(0xFF15803D);
  static const chip = Color(0xFFCCFBF1);
}

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: C.teal, primary: C.teal),
      scaffoldBackgroundColor: C.paper,
      appBarTheme: const AppBarTheme(backgroundColor: C.paper, foregroundColor: C.navy, elevation: 0, scrolledUnderElevation: 0),
      navigationBarTheme: const NavigationBarThemeData(backgroundColor: Colors.white, indicatorColor: C.chip, height: 72),
    );
