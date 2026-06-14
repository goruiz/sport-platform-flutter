import 'package:sport_platform/modules/events/event_types/leagues/data/models/match_model.dart';
import 'package:sport_platform/modules/events/event_types/leagues/data/models/team_event_model.dart';

class LeagueStanding {
  final String teamId;
  final String teamName;
  int mp;
  int w;
  int d;
  int l;
  int gf;
  int ga;

  LeagueStanding({
    required this.teamId,
    required this.teamName,
    this.mp = 0,
    this.w = 0,
    this.d = 0,
    this.l = 0,
    this.gf = 0,
    this.ga = 0,
  });

  int get pts => w * 3 + d;
  int get gd => gf - ga;

  static List<LeagueStanding> compute(
    List<TeamEventModel> teams,
    List<MatchModel> matches,
  ) {
    final acc = <String, LeagueStanding>{};
    for (final t in teams) {
      acc[t.teamId] = LeagueStanding(teamId: t.teamId, teamName: t.teamName);
    }
    for (final m in matches) {
      if (m.status != 'FINISHED') continue;
      final hs = m.homeScore;
      final as_ = m.awayScore;
      if (hs == null || as_ == null) continue;
      final home = acc[m.homeTeamId];
      final away = acc[m.awayTeamId];
      if (home == null || away == null) continue;
      home.mp++;
      away.mp++;
      home.gf += hs;
      home.ga += as_;
      away.gf += as_;
      away.ga += hs;
      if (hs > as_) {
        home.w++;
        away.l++;
      } else if (hs < as_) {
        away.w++;
        home.l++;
      } else {
        home.d++;
        away.d++;
      }
    }
    return acc.values.toList()
      ..sort((a, b) {
        final byPts = b.pts.compareTo(a.pts);
        if (byPts != 0) return byPts;
        final byGD = b.gd.compareTo(a.gd);
        if (byGD != 0) return byGD;
        final byGF = b.gf.compareTo(a.gf);
        if (byGF != 0) return byGF;
        return a.teamName.compareTo(b.teamName);
      });
  }
}
