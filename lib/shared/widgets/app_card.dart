import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';
import 'package:sport_platform/core/theme/app_dimensions.dart';

/// La tarjeta base de la app: superficie translúcida con borde fino. Si recibe [onTap] se puede tocar
/// (con su efecto de pulsación) y si recibe [accent] se tiñe de ese color para destacarla.
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? accent;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.accent,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = accent;
    return Padding(
      padding: margin,
      child: Material(
        color: accentColor == null
            ? AppColors.inputFill
            : accentColor.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(
            color: accentColor == null
                ? AppColors.inputBorder
                : accentColor.withValues(alpha: 0.45),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
