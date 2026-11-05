import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';

/// Los estilos de texto de la app. Una jerarquía corta y constante: el título manda,
/// el cuerpo se lee bien y lo secundario nunca baja de 12 px.
class AppTextStyles {
  /// El título de una pantalla o de una tarjeta destacada.
  static const TextStyle pageTitle = TextStyle(
    color: AppColors.white,
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );

  /// El título de cada sección dentro de una pantalla.
  static const TextStyle sectionTitle = TextStyle(
    color: AppColors.white,
    fontSize: 17,
    fontWeight: FontWeight.w700,
  );

  /// El título de una tarjeta o de una fila de lista.
  static const TextStyle cardTitle = TextStyle(
    color: AppColors.white,
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  /// Texto corrido.
  static const TextStyle body = TextStyle(color: AppColors.white, fontSize: 14);

  /// Texto corrido de apoyo (descripciones, pistas).
  static const TextStyle bodyMuted = TextStyle(
    color: AppColors.whiteSubtle,
    fontSize: 14,
  );

  /// Datos secundarios: fechas, lugares, etiquetas pequeñas.
  static const TextStyle caption = TextStyle(
    color: AppColors.whiteSubtle,
    fontSize: 12.5,
  );

  /// Rótulo en mayúsculas encima de un bloque (p. ej. «CRONOLOGÍA»).
  static const TextStyle overline = TextStyle(
    color: AppColors.primaryLight,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
  );

  /// El marcador de un partido. Las cifras tabulares evitan que el resultado «baile».
  static const TextStyle score = TextStyle(
    color: AppColors.white,
    fontSize: 30,
    fontWeight: FontWeight.w800,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
