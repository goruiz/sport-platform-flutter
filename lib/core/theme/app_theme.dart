import 'package:flutter/material.dart';
import 'package:sport_platform/main.dart';
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
