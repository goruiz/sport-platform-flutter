import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';

/// Un círculo con la imagen de un equipo o de una persona (logo, foto) y, si no la hay, sus iniciales sobre un color
/// que siempre es el mismo para ese nombre. Así un equipo se reconoce de un vistazo en cualquier lista de partidos.
class InitialsAvatar extends StatelessWidget {
  final String name;
  final String? logoUrl;
  final double size;

  const InitialsAvatar({
    super.key,
    required this.name,
    this.logoUrl,
    this.size = 44,
  });

  /// Hasta dos iniciales: «Los Halcones» → «LH», «Tigres» → «TI». Un nombre vacío da «?».
  static String initialsOf(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      final word = words.first;
      return word.substring(0, word.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  /// El mismo nombre da siempre el mismo color (no se usa `hashCode`: no está garantizado entre ejecuciones).
  static Color colorOf(String name) {
    final sum = name.codeUnits.fold<int>(0, (total, unit) => (total * 31 + unit) & 0x7fffffff);
    return AppColors.crestPalette[sum % AppColors.crestPalette.length];
  }

  @override
  Widget build(BuildContext context) {
    final color = colorOf(name);
    final logo = logoUrl;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.28),
        border: Border.all(color: color.withValues(alpha: 0.8), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: logo != null && logo.isNotEmpty
          ? Image.network(
              logo,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _initials(),
            )
          : _initials(),
    );
  }

  Widget _initials() => Text(
        initialsOf(name),
        style: TextStyle(
          color: AppColors.white,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      );
}
