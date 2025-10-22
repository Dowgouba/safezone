import 'package:flutter/material.dart';

class AppColors {
  // 🎨 Couleurs globales
  static const Color primary = Color(0xFF2B78B7); // Bleu principal SafeZone
  static const Color accent = Colors.redAccent;
  static const Color background = Color(0xFFF5F7FA);
  static const Color text = Color(0xFF043A68);

  // ⚠️ Couleur spécifique à la partie alerte
  static const Color alerte = Color.fromARGB(255, 0, 34, 80);
}

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  primaryColor: AppColors.primary,
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    secondary: AppColors.accent,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.accent,
    foregroundColor: Colors.white,
  ),
);
