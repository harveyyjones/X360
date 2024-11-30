import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/stored_schedule.dart';

class ScheduleRepository {
  final SharedPreferences _prefs;
  static const _keyPrefix = 'schedule_';

  ScheduleRepository(this._prefs);

  Future<void> saveSchedule(StoredSchedule schedule) async {
    final key = _keyPrefix + schedule.date.toIso8601String().split('T')[0];
    await _prefs.setString(key, jsonEncode(schedule.toJson()));
  }

  Future<StoredSchedule?> getSchedule(DateTime date) async {
    final key = _keyPrefix + date.toIso8601String().split('T')[0];
    final data = _prefs.getString(key);
    if (data == null) return null;

    try {
      return StoredSchedule.fromJson(jsonDecode(data));
    } catch (e) {
      print('Error loading schedule: $e');
      return null;
    }
  }

  Future<List<DateTime>> getStoredDates() async {
    return _prefs
        .getKeys()
        .where((key) => key.startsWith(_keyPrefix))
        .map((key) => DateTime.parse(key.substring(_keyPrefix.length)))
        .toList();
  }
}
