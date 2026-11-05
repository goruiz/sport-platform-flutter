import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primaryDark = Color(0xFF0A1F0A);
  static const Color backgroundStart = Color(0xFF1B5E20);
  static const Color backgroundEnd = Color(0xFF071407);
  static const Color white = Color(0xFFFFFFFF);
  static const Color whiteSubtle = Color(0xB3FFFFFF);
  static const Color inputFill = Color(0x1AFFFFFF);
  static const Color inputBorder = Color(0x33FFFFFF);
  static const Color error = Color(0xFFEF5350);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  static const Color sheetBackground = Color(0xFF0F2A0F);
  static const Color warningLight = Color(0xFFFFB347);
  static const Color rescheduled = Color(0xFF64B5F6);
  static const Color podiumGold = Color(0xFFFFD700);
  static const Color podiumSilver = Color(0xFFB0B8C1);
  static const Color podiumBronze = Color(0xFFCD7F32);
  static const Color cardYellow = Color(0xFFFFEB3B);
  static const Color cardRed = Color(0xFFE53935);

  /// Fondo de los botones principales. Con texto blanco da un contraste de 5:1; el verde claro
  /// ([primaryLight]) solo da 2,8:1, así que se reserva para iconos, enlaces y acentos sobre fondo oscuro.
  static const Color action = primary;

  /// Los colores de los escudos de equipo: cada equipo toma siempre el mismo según su nombre.
  static const List<Color> crestPalette = [
    Color(0xFF2E7D32),
    Color(0xFF1565C0),
    Color(0xFFE65100),
    Color(0xFF6A1B9A),
    Color(0xFF00838F),
    Color(0xFFAD1457),
    Color(0xFF9E7B00),
    Color(0xFF37474F),
  ];
}
