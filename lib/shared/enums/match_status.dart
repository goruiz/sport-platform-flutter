import 'package:flutter/material.dart';
import 'package:sport_platform/core/constants/locale_keys.g.dart';
import 'package:sport_platform/core/theme/app_colors.dart';

/// El estado de un partido (`MatchStatus` del backend), con el texto con que se lee y el color con que se pinta.
///
/// Un estado que esta versión de la app no conoce es [unknown]: se enseña como «Estado desconocido» y no se confunde
/// con «Programado», que además es lo que haría creer que el partido sigue en pie.
enum MatchStatus {
  scheduled('SCHEDULED', LocaleKeys.leagues_match_status_scheduled, AppColors.primaryLight),
  inProgress('IN_PROGRESS', LocaleKeys.leagues_match_status_in_progress, AppColors.warning),
  finished('FINISHED', LocaleKeys.leagues_match_status_finished, AppColors.whiteSubtle),
  cancelled('CANCELLED', LocaleKeys.leagues_match_status_cancelled, AppColors.error),
  postponed('POSTPONED', LocaleKeys.leagues_match_status_postponed, AppColors.warningLight),
  suspended('SUSPENDED', LocaleKeys.leagues_match_status_suspended, AppColors.error),
  rescheduled('RESCHEDULED', LocaleKeys.leagues_match_status_rescheduled, AppColors.rescheduled),
  completed('COMPLETED', LocaleKeys.leagues_match_status_finished, AppColors.whiteSubtle),
  unknown(null, LocaleKeys.leagues_match_status_unknown, AppColors.whiteSubtle);

  const MatchStatus(this.apiValue, this.label, this.color);

  /// El texto con que el backend lo manda; null en [unknown], que es todo lo que no se reconoce.
  final String? apiValue;

  /// La clave de traducción del nombre del estado.
  final String label;

  final Color color;

  static MatchStatus fromApi(String? value) {
    final normalized = value?.toUpperCase();
    for (final status in values) {
      if (status.apiValue != null && status.apiValue == normalized) return status;
    }
    return MatchStatus.unknown;
  }
}
