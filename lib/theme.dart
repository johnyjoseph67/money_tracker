import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      // App bar: white with navy content (also used by the Settings page)
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: C.navy,
        elevation: 3,
        scrolledUnderElevation: 3,
        shadowColor: Color(0x330F172A),
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      // Bottom bar: white surface, mint pill behind the selected tab, teal selected / slate unselected
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: const Color(0x330F172A),
        indicatorColor: C.chip,
        height: 74,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(color: s.contains(WidgetState.selected) ? C.teal : C.slate, size: 26),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? C.teal : C.slate,
          ),
        ),
      ),
    );