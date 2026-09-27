import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';

mixin SnackMixin<T extends StatefulWidget> on State<T> {
  void showSnack(
    String message, {
    bool isError = false,
    bool isWarning = false,
  }) {
    if (!mounted) return;
    Color bg = AppColors.success;
    if (isError) bg = AppColors.error;
    if (isWarning) bg = AppColors.warning;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        duration:
            isWarning ? const Duration(seconds: 6) : const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
