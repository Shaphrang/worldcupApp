import 'package:flutter/material.dart';

class AppTheme {
  static const navy = Color(0xFF081A2F);
  static const card = Color(0xFF102A47);
  static const gold = Color(0xFFFFC857);
  static const red = Color(0xFFE63946);
  static const green = Color(0xFF2EC4B6);
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: navy,
    colorScheme: ColorScheme.fromSeed(seedColor: gold, brightness: Brightness.dark, surface: card),
    cardTheme: CardThemeData(color: card, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
    inputDecorationTheme: InputDecorationTheme(border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
  );
}
