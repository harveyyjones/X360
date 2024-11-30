import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/preferences/base_preferences.dart';
import '../services/preferences_factory.dart';

final preferencesProvider =
    StateNotifierProvider<PreferencesNotifier, BasePreferences?>((ref) {
  return PreferencesNotifier();
});

class PreferencesNotifier extends StateNotifier<BasePreferences?> {
  PreferencesNotifier() : super(null) {
    _loadSavedPreferences();
  }

  Future<void> _loadSavedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPrefs = prefs.getString('last_preferences');

      if (savedPrefs != null) {
        final prefsMap = jsonDecode(savedPrefs) as Map<String, dynamic>;
        final stringMap = prefsMap.map(
          (key, value) => MapEntry(key, value?.toString() ?? ''),
        );
        state = PreferencesFactory.createPreferences(stringMap);
      }
    } catch (e) {
      print('Error loading preferences: $e');
    }
  }

  Future<void> updatePreferences(BasePreferences preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'last_preferences', jsonEncode(preferences.toMap()));
      state = preferences;
    } catch (e) {
      print('Error saving preferences: $e');
    }
  }

  void clearPreferences() {
    state = null;
  }
}
