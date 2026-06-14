class EventScheduleConfigModel {
  final String? id;
  final String eventId;
  final List<String> playDays;
  final String startTime;
  final int matchDurationMinutes;
  final int breakBetweenHalvesMinutes;
  final int breakBetweenMatchesMinutes;
  final String? courtId;

  const EventScheduleConfigModel({
    this.id,
    required this.eventId,
    required this.playDays,
    required this.startTime,
    required this.matchDurationMinutes,
    required this.breakBetweenHalvesMinutes,
    required this.breakBetweenMatchesMinutes,
    this.courtId,
  });

  factory EventScheduleConfigModel.fromJson(Map<String, dynamic> json) {
    return EventScheduleConfigModel(
      id: json['id']?.toString(),
      eventId: json['eventId']?.toString() ?? '',
      playDays: (json['playDays'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      startTime: json['startTime']?.toString() ?? '09:00',
      matchDurationMinutes: (json['matchDurationMinutes'] as num?)?.toInt() ?? 90,
      breakBetweenHalvesMinutes:
          (json['breakBetweenHalvesMinutes'] as num?)?.toInt() ?? 15,
      breakBetweenMatchesMinutes:
          (json['breakBetweenMatchesMinutes'] as num?)?.toInt() ?? 30,
      courtId: json['courtId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'playDays': playDays,
        'startTime': startTime,
        'matchDurationMinutes': matchDurationMinutes,
        'breakBetweenHalvesMinutes': breakBetweenHalvesMinutes,
        'breakBetweenMatchesMinutes': breakBetweenMatchesMinutes,
        if (courtId != null) 'courtId': courtId,
      };

  EventScheduleConfigModel copyWith({
    String? id,
    String? eventId,
    List<String>? playDays,
    String? startTime,
    int? matchDurationMinutes,
    int? breakBetweenHalvesMinutes,
    int? breakBetweenMatchesMinutes,
    String? courtId,
  }) =>
      EventScheduleConfigModel(
        id: id ?? this.id,
        eventId: eventId ?? this.eventId,
        playDays: playDays ?? this.playDays,
        startTime: startTime ?? this.startTime,
        matchDurationMinutes: matchDurationMinutes ?? this.matchDurationMinutes,
        breakBetweenHalvesMinutes:
            breakBetweenHalvesMinutes ?? this.breakBetweenHalvesMinutes,
        breakBetweenMatchesMinutes:
            breakBetweenMatchesMinutes ?? this.breakBetweenMatchesMinutes,
        courtId: courtId ?? this.courtId,
      );
}
