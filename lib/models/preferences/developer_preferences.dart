// models/preferences/developer_preferences.dart
import 'package:planner_ai/models/preferences/base_preferences.dart';

class DeveloperPreferences extends BasePreferences {
  final String? employmentType;
  final String? workHours;
  final String? meetingFrequencyForCompanyDevelopers;
  final String? availabilityCompany;
  final String? fixedHours;
  final String communicationStyle;
  final String deepWorkHours;

  DeveloperPreferences({
    required super.occupation,
    this.employmentType,
    this.workHours,
    this.meetingFrequencyForCompanyDevelopers,
    this.availabilityCompany,
    this.fixedHours,
    required this.communicationStyle,
    required this.deepWorkHours,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'occupation': occupation,
      'employmentType': employmentType,
      'workHours': workHours,
      'meeting_frequency_for_company_developers':
          meetingFrequencyForCompanyDevelopers,
      'dev_availability_company': availabilityCompany,
      'dev_fixed_hours_freelancer': fixedHours,
      'communicationStyle': communicationStyle,
      'dev_deep_work_hours': deepWorkHours,
    };
  }
}
