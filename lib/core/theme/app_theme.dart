import 'package:flutter/material.dart';

/// Theme dipakai bersama oleh 3 track supaya tampilan konsisten
/// walau dikerjakan paralel oleh 3 orang berbeda.
/// Jangan override warna/font manual di masing-masing screen —
/// tarik dari Theme.of(context) agar tetap seragam.
ThemeData buildAppTheme() {
  const seedColor = Color(0xFF2F6FED);
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    cardTheme: const CardThemeData(
      margin: EdgeInsets.symmetric(vertical: 6),
      elevation: 0.5,
    ),
  );
}