import 'package:flutter/material.dart';
import 'package:sport_platform/core/theme/app_colors.dart';

enum MatchStatus {
  scheduled,
  inProgress,
  finished,
  cancelled,
  postponed,
  suspended,
  rescheduled,
  completed;

  static MatchStatus fromString(String s) {
    switch (s.toUpperCase()) {
      case 'IN_PROGRESS':
        return MatchStatus.inProgress;
      case 'FINISHED':
        return MatchStatus.finished;
      case 'CANCELLED':
        return MatchStatus.cancelled;
      case 'POSTPONED':
        return MatchStatus.postponed;
      case 'SUSPENDED':
        return MatchStatus.suspended;
      case 'RESCHEDULED':
        return MatchStatus.rescheduled;
      case 'COMPLETED':
        return MatchStatus.completed;
      default:
        return MatchStatus.scheduled;
    }
  }

  String toJson() {
    switch (this) {
      case MatchStatus.scheduled:
        return 'SCHEDULED';
      case MatchStatus.inProgress:
        return 'IN_PROGRESS';
      case MatchStatus.finished:
        return 'FINISHED';
      case MatchStatus.cancelled:
        return 'CANCELLED';
      case MatchStatus.postponed:
        return 'POSTPONED';
      case MatchStatus.suspended:
        return 'SUSPENDED';
      case MatchStatus.rescheduled:
        return 'RESCHEDULED';
      case MatchStatus.completed:
        return 'COMPLETED';
    }
  }

  String get label {
    switch (this) {
      case MatchStatus.scheduled:
        return 'leagues.match_status_scheduled';
      case MatchStatus.inProgress:
        return 'leagues.match_status_in_progress';
      case MatchStatus.finished:
        return 'leagues.match_status_finished';
      case MatchStatus.cancelled:
        return 'leagues.match_status_cancelled';
      case MatchStatus.postponed:
        return 'leagues.match_status_postponed';
      case MatchStatus.suspended:
        return 'leagues.match_status_suspended';
      case MatchStatus.rescheduled:
        return 'leagues.match_status_rescheduled';
      case MatchStatus.completed:
        return 'leagues.match_status_finished';
    }
  }

  Color get color {
    switch (this) {
      case MatchStatus.scheduled:
        return AppColors.primaryLight;
      case MatchStatus.inProgress:
        return AppColors.warning;
      case MatchStatus.finished:
        return AppColors.whiteSubtle;
      case MatchStatus.cancelled:
        return AppColors.error;
      case MatchStatus.postponed:
        return AppColors.warningLight;
      case MatchStatus.suspended:
        return AppColors.error;
      case MatchStatus.rescheduled:
        return AppColors.rescheduled;
      case MatchStatus.completed:
        return AppColors.whiteSubtle;
    }
  }
}
