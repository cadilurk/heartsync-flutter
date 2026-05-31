import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFFF7F0F4);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFEEDBE7);
  static const title = Color(0xFFD946B7);
  static const subtitle = Color(0xFF6B7280);
  static const active = Color(0xFFF43F7B);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.active),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.active),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.active,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        final isSelected = states.contains(MaterialState.selected);
        return TextStyle(
          fontSize: 10,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          overflow: TextOverflow.ellipsis,
        );
      }),
    ),
  );
}
