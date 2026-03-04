import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF0A0A0F);
  static const bgCard = Color(0xFF111118);
  static const bgElevated = Color(0xFF16161F);
  static const border = Color(0xFF1E1E2E);
  static const borderBright = Color(0xFF2E2E45);
  static const accent = Color(0xFF6C63FF);
  static const accentGlow = Color(0x336C63FF);
  static const accentHover = Color(0xFF8B85FF);
  static const success = Color(0xFF22C55E);
  static const successGlow = Color(0x2622C55E);
  static const danger = Color(0xFFEF4444);
  static const dangerGlow = Color(0x26EF4444);
  static const warning = Color(0xFFF59E0B);
  static const textPrimary = Color(0xFFF0F0F8);
  static const textSecondary = Color(0xFF8888AA);
  static const textMuted = Color(0xFF55556A);
  static const pink = Color(0xFFEC4899);
  static const teal = Color(0xFF14B8A6);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          secondary: AppColors.success,
          surface: AppColors.bgCard,
          error: AppColors.danger,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bgCard,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.bgCard,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: AppColors.textMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.bgElevated,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.danger),
          ),
          labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          hintStyle: const TextStyle(color: AppColors.textMuted),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        
        dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.textPrimary, fontSize: 15),
          bodyMedium: TextStyle(color: AppColors.textPrimary, fontSize: 14),
          bodySmall: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          titleLarge: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800),
          titleMedium: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700),
          titleSmall: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
          labelSmall: TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
      );
}
