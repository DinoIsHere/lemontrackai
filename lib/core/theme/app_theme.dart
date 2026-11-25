import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.lemon,
          onPrimary: Colors.black,
          secondary: AppColors.lemonDark,
          onSecondary: Colors.black,
          tertiary: AppColors.lemon,
          surface: Colors.black,
          onSurface: Color(0xFFEDEDED),
          surfaceContainerHighest: Color(0xFF1F1F1F),
          outline: Color(0xFF3A3A3A),
          outlineVariant: Color(0xFF2A2A2A),
        ),
        fontFamily: 'PlusJakartaSans',
      );
}