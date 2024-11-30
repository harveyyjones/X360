// services/preferences_factory.dart
import 'package:planner_ai/models/preferences/base_preferences.dart';
import 'package:planner_ai/models/preferences/developer_preferences.dart';
import 'package:planner_ai/models/preferences/student_preferences.dart';

class PreferencesFactory {
  static BasePreferences createPreferences(Map<String, String> answers) {
    return switch (answers['occupation']) {
      'developer' => DeveloperPreferences(
          occupation: answers['occupation']!,
          employmentType:
              answers['dev_employment'] ?? 'No employment type defined',
          workHours: answers['dev_workHours'] ?? 'No work hours defined',
          communicationStyle:
              answers['dev_communication'] ?? 'No communication style defined',
          meetingFrequencyForCompanyDevelopers:
              answers['meeting_frequency_for_company_developers'] ??
                  'No meeting frequency defined',
          fixedHours: answers['fixed_hours_freelance_developer'] ??
              'No fixed hours defined',
          deepWorkHours:
              answers['dev_deep_work_hours'] ?? 'No deep work hours defined',
        ),
      'student' => StudentPreferences(
          occupation: answers['occupation']!,
          deepWorkHours:
              answers['deep_work_student'] ?? 'No deep work hours defined',
          timePreference: answers['time_preference_student'] ??
              'No time preference defined',
          environment:
              answers['environment_student'] ?? 'No environment defined',
        ),
      _ => throw Exception('Unknown occupation type'),
    };
  }
}
