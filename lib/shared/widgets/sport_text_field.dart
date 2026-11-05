import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sport_platform/core/theme/app_colors.dart';

/// El campo de texto de los formularios: icono a la izquierda y el aspecto que define el tema.
/// Pensado para formularios rápidos: [textInputAction] y [onSubmitted] permiten avanzar de campo o enviar
/// desde el teclado, y [autofillHints] deja que el gestor de contraseñas del sistema lo rellene.
class SportTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;

  /// Una pista fija bajo el campo (p. ej. las reglas de una contraseña), visible antes de equivocarse.
  final String? helperText;

  const SportTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.validator,
    this.inputFormatters,
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      autofillHints: autofillHints,
      style: const TextStyle(color: AppColors.white, fontSize: 15),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffixIcon,
        helperText: helperText,
        helperMaxLines: 3,
        helperStyle: const TextStyle(color: AppColors.whiteSubtle, fontSize: 12.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
