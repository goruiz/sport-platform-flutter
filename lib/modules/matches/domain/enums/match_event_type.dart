import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';

/// Lo que hizo un jugador en un partido (`MatchEventType` del backend): una línea de su cronología.
enum MatchEventType {
  goal('GOAL', Icons.sports_soccer, AppColors.primaryLight),
  assist('ASSIST', Icons.compare_arrows, AppColors.info),
  yellowCard('YELLOW_CARD', Icons.square_rounded, AppColors.cardYellow),
  redCard('RED_CARD', Icons.square_rounded, AppColors.cardRed),
  foul('FOUL', Icons.front_hand_outlined, AppColors.warning);

  const MatchEventType(this.apiValue, this.icon, this.color);

  final String apiValue;
  final IconData icon;
  final Color color;

  /// Null si el backend trae un tipo que esta versión de la app no conoce.
  static MatchEventType? fromApi(String? value) {
    for (final type in values) {
      if (type.apiValue == value) return type;
    }
    return null;
  }

  String get translationKey => 'match_events.types.$apiValue';
}
