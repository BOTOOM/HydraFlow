import 'package:flutter/material.dart';

class HydraTheme {
  static const navy = Color(0xFF0B1D33);
  static const mist = Color(0xFFF2F7FB);
  static const aqua = Color(0xFF1FB6C9);
  static const coral = Color(0xFFFF7A59);
  static const mint = Color(0xFF3DD598);

  static ThemeData light() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: aqua, brightness: Brightness.light),
    scaffoldBackgroundColor: mist,
    fontFamily: 'sans',
    cardTheme: const CardThemeData(margin: EdgeInsets.zero, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20)))),
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)))),
  );
  static ThemeData dark() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: aqua, brightness: Brightness.dark),
    scaffoldBackgroundColor: navy,
    cardTheme: const CardThemeData(margin: EdgeInsets.zero, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20)))),
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)))),
  );
}
