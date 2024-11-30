// models/preferences/student_preferences.dart
import 'package:planner_ai/models/preferences/base_preferences.dart';

class StudentPreferences extends BasePreferences {
  final String? timePreference;
  final String? deepWorkHours;
  final String? environment;

  StudentPreferences({
    required super.occupation,
    required this.timePreference,
    required this.deepWorkHours,
    required this.environment,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'occupation': occupation,
      'time_preference_student': timePreference,
      'deep_work_student': deepWorkHours,
      'environment_student': environment,
    };
  }
}
