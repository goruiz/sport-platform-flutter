import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';

/// Limita el ancho de toda la app a una columna del tamaño de un teléfono y la centra.
/// En un teléfono no cambia nada; en una tablet, en la web o en Windows evita que las tarjetas y las listas se estiren
/// de borde a borde (con huecos enormes a un lado) y mantiene el diseño tal como se pensó.
/// Los diálogos, las hojas inferiores y los avisos viven dentro del navegador de la app, así que también respetan el ancho.
class AppViewport extends StatelessWidget {
  final Widget child;

  const AppViewport({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.backgroundEnd,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border.symmetric(
                vertical: BorderSide(color: AppColors.inputFill),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
