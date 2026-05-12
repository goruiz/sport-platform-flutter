import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get sportsPlatform => ThemeData(
    fontFamily: 'sans-serif',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ),
  );
}
