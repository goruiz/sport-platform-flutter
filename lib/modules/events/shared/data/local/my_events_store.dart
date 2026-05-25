import 'package:shared_preferences/shared_preferences.dart';

/// Persists the set of event IDs created by this user on this device,
/// grouped by eventTypeId. Used to populate the "My events" tab without
/// requiring a `createdBy` field from the backend.
class MyEventsStore {
  static const _keyPrefix = 'my_events_';

  static String _key(String eventTypeId) => '$_keyPrefix$eventTypeId';

  static Future<Set<String>> getIds(String eventTypeId) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key(eventTypeId)) ?? []).toSet();
  }

  static Future<void> add(String eventTypeId, String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList(_key(eventTypeId)) ?? []).toSet()
      ..add(eventId);
    await prefs.setStringList(_key(eventTypeId), ids.toList());
  }

  static Future<void> remove(String eventTypeId, String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList(_key(eventTypeId)) ?? []).toSet()
      ..remove(eventId);
    await prefs.setStringList(_key(eventTypeId), ids.toList());
  }
}
