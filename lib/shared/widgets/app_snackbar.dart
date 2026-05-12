import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';

enum SnackbarType { success, error, warning, info }

class AppSnackbar {
  static void success(BuildContext context, String message) => _show(
        context,
        message: message,
        type: SnackbarType.success,
      );

  static void error(BuildContext context, String message) => _show(
        context,
        message: message,
        type: SnackbarType.error,
      );

  static void warning(BuildContext context, String message) => _show(
        context,
        message: message,
        type: SnackbarType.warning,
      );

  static void info(BuildContext context, String message) => _show(
        context,
        message: message,
        type: SnackbarType.info,
      );

  static void _show(
    BuildContext context, {
    required String message,
    required SnackbarType type,
  }) {
    final config = _config(type);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: config.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: config.borderColor, width: 1),
            ),
            child: Row(
              children: [
                Icon(config.icon, color: AppColors.white, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  static _SnackbarConfig _config(SnackbarType type) => switch (type) {
        SnackbarType.success => _SnackbarConfig(
            icon: Icons.check_circle_outline,
            backgroundColor: AppColors.success.withValues(alpha: 0.9),
            borderColor: AppColors.success,
          ),
        SnackbarType.error => _SnackbarConfig(
            icon: Icons.error_outline,
            backgroundColor: AppColors.error.withValues(alpha: 0.9),
            borderColor: AppColors.error,
          ),
        SnackbarType.warning => _SnackbarConfig(
            icon: Icons.warning_amber_outlined,
            backgroundColor: AppColors.warning.withValues(alpha: 0.9),
            borderColor: AppColors.warning,
          ),
        SnackbarType.info => _SnackbarConfig(
            icon: Icons.info_outline,
            backgroundColor: AppColors.info.withValues(alpha: 0.9),
            borderColor: AppColors.info,
          ),
      };
}

class _SnackbarConfig {
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;

  const _SnackbarConfig({
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
  });
}
