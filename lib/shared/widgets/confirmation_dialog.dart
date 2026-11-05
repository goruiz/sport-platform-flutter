import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';

/// Pregunta «¿seguro?» antes de una acción. Devuelve true solo si la persona confirma.
/// Con [destructive] (lo normal: eliminar, borrar) el botón de confirmar va en rojo; para acciones que
/// no destruyen nada, como cerrar sesión, va en el color de la app.
Future<bool> showConfirmationDialog(
  BuildContext context, {
  required String title,
  String? content,
  required String confirmLabel,
  required String cancelLabel,
  bool destructive = true,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: content != null ? Text(content) : null,
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          style: TextButton.styleFrom(foregroundColor: AppColors.whiteSubtle),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.white,
                )
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed == true;
}
