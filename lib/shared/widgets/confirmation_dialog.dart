import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';

Future<bool> showConfirmationDialog(
  BuildContext context, {
  required String title,
  String? content,
  required String confirmLabel,
  required String cancelLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.sheetBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: const TextStyle(color: AppColors.white)),
      content: content != null
          ? Text(content, style: const TextStyle(color: AppColors.whiteSubtle))
          : null,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancelLabel,
              style: const TextStyle(color: AppColors.whiteSubtle)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel,
              style: const TextStyle(color: AppColors.error)),
        ),
      ],
    ),
  );
  return confirmed == true;
}
