class EventModel {
  final String id;
  final String name;
  final String? description;
  final String format;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? eventTypeName;

  const EventModel({
    required this.id,
    required this.name,
    this.description,
    required this.format,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    this.updatedAt,
    this.eventTypeName,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final eventType = json['eventType'] as Map<String, dynamic>?;
    return EventModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      format: json['format']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'].toString())
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'].toString())
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : null,
      eventTypeName: eventType?['name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'format': format,
        'status': status,
        'startDate': _apiDate(startDate),
        'endDate': _apiDate(endDate),
      };

  EventModel copyWith({
    String? id,
    String? name,
    String? description,
    String? format,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? eventTypeName,
  }) =>
      EventModel(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        format: format ?? this.format,
        status: status ?? this.status,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        eventTypeName: eventTypeName ?? this.eventTypeName,
      );

  static String _apiDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
