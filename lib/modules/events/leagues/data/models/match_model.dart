class MatchModel {
  final String id;
  final String homeTeamId;
  final String awayTeamId;
  final DateTime matchDate;
  final String? location;
  final String status;
  final int? homeScore;
  final int? awayScore;
  final String? courtId;
  final String eventId;
  final DateTime createdAt;

  const MatchModel({
    required this.id,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.matchDate,
    this.location,
    required this.status,
    this.homeScore,
    this.awayScore,
    this.courtId,
    required this.eventId,
    required this.createdAt,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id']?.toString() ?? '',
      homeTeamId: json['homeTeamId']?.toString() ?? '',
      awayTeamId: json['awayTeamId']?.toString() ?? '',
      matchDate: json['matchDate'] != null
          ? DateTime.parse(json['matchDate'].toString())
          : DateTime.now(),
      location: json['location']?.toString(),
      status: json['status']?.toString() ?? 'SCHEDULED',
      homeScore: json['homeScore'] as int?,
      awayScore: json['awayScore'] as int?,
      courtId: json['courtId']?.toString(),
      eventId: json['eventId']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'homeTeamId': homeTeamId,
        'awayTeamId': awayTeamId,
        'matchDate': _apiDateTime(matchDate),
        'status': status,
        'eventId': eventId,
        if (location != null) 'location': location,
        if (courtId != null) 'courtId': courtId,
        if (homeScore != null) 'homeScore': homeScore,
        if (awayScore != null) 'awayScore': awayScore,
      };

  MatchModel copyWith({
    String? id,
    String? homeTeamId,
    String? awayTeamId,
    DateTime? matchDate,
    String? location,
    String? status,
    int? homeScore,
    int? awayScore,
    String? courtId,
    String? eventId,
    DateTime? createdAt,
  }) =>
      MatchModel(
        id: id ?? this.id,
        homeTeamId: homeTeamId ?? this.homeTeamId,
        awayTeamId: awayTeamId ?? this.awayTeamId,
        matchDate: matchDate ?? this.matchDate,
        location: location ?? this.location,
        status: status ?? this.status,
        homeScore: homeScore ?? this.homeScore,
        awayScore: awayScore ?? this.awayScore,
        courtId: courtId ?? this.courtId,
        eventId: eventId ?? this.eventId,
        createdAt: createdAt ?? this.createdAt,
      );

  static String _apiDateTime(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}'
      'T${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:00';
}
