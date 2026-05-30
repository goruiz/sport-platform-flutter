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
}
