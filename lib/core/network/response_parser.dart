/// Helpers for unwrapping backend responses that may come as a bare value
/// or wrapped in {"data": ...}.
class ResponseParser {
  ResponseParser._();

  static List<dynamic> toList(dynamic raw) =>
      raw is List ? raw : (raw['data'] as List<dynamic>);

  static Map<String, dynamic> toMap(dynamic raw) {
    final map = raw as Map<String, dynamic>;
    if (map['data'] is Map<String, dynamic>) {
      return map['data'] as Map<String, dynamic>;
    }
    return map;
  }
}
