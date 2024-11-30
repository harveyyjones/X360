// services/question/developer_question_service.dart
import 'package:flutter/material.dart';
import 'package:planner_ai/models/question.dart';
import 'package:planner_ai/services/question/base_question_service.dart';

class DeveloperQuestionService extends BaseQuestionService {
  @override
  List<Question> getInitialQuestions() {
    return [
      Question(
        id: 'dev_employment',
        text: 'What type of employment?',
        subtitle: 'Choose your work arrangement',
        options: [
          const QuestionOption(
            id: 'company',
            title: 'Company Employee',
            subtitle: 'Working for a company with fixed hours',
            icon: Icons.business,
          ),
          const QuestionOption(
            id: 'freelance',
            title: 'Freelancer',
            subtitle: 'Independent work with flexible hours',
            icon: Icons.laptop,
          ),
        ],
      ),

      // Common question.
    ];
  }

  @override
  List<Question> getNextQuestions(Map<String, String> answers) {
    // Company specific questions
    if (answers['dev_employment'] == 'company') {
      if (!answers.containsKey('dev_workHours')) {
        return [
          Question(
            id: 'dev_workHours',
            text: 'What are your working hours?',
            subtitle: 'Select your typical schedule',
            options: [
              const QuestionOption(
                id: '9_5',
                title: '9 AM - 5 PM',
                subtitle: 'Standard business hours',
                icon: Icons.schedule,
              ),
              const QuestionOption(
                id: '8_4',
                title: '8 AM - 4 PM',
                subtitle: 'Early schedule',
                icon: Icons.schedule,
              ),
              const QuestionOption(
                id: '10_6',
                title: '10 AM - 6 PM',
                subtitle: 'Late schedule',
                icon: Icons.schedule,
              ),
            ],
          ),
        ];
      }

      // Add meeting interruption question after work hours
      if (!answers.containsKey('meeting_frequency_for_company_developers')) {
        return [
          Question(
            id: 'meeting_frequency_for_company_developers',
            text: 'Are you often interrupted by meetings during shifts?',
            subtitle: 'This helps plan your focus time',
            options: [
              const QuestionOption(
                id: 'frequent',
                title: 'Frequent Meetings',
                subtitle: 'Multiple meetings per day',
                icon: Icons.groups,
              ),
              const QuestionOption(
                id: 'moderate',
                title: 'Moderate Meetings',
                subtitle: 'Few meetings per week',
                icon: Icons.calendar_today,
              ),
              const QuestionOption(
                id: 'rare',
                title: 'Rare Meetings',
                subtitle: 'Minimal meeting interruptions',
                icon: Icons.do_not_disturb,
              ),
            ],
          ),
        ];
      }
    }
    if (!answers.containsKey('dev_deep_work_hours')) {
      if (answers.containsKey('meeting_frequency_for_company_developers')) {
        // Common question.
        return [
          Question(
            id: 'dev_deep_work_hours',
            text: 'How many hours of deep work do you want per day?',
            subtitle: 'Choose your preferred deep work duration',
            options: [
              const QuestionOption(
                id: 'low',
                title: '2-3 Hours',
                subtitle: 'Light focus sessions throughout the day',
                icon: Icons.hourglass_empty,
              ),
              const QuestionOption(
                id: 'medium',
                title: '4-5 Hours',
                subtitle: 'Balanced deep work periods',
                icon: Icons.laptop_mac,
              ),
              const QuestionOption(
                id: 'high',
                title: '6+ Hours',
                subtitle: 'Extended deep work sessions',
                icon: Icons.hourglass_full,
              ),
            ],
          ),
        ];
      }
    }
    // Freelance specific questions
    if (answers['dev_employment'] == 'freelance') {
      if (!answers.containsKey('dev_availability_freelance')) {
        return [
          Question(
            id: 'dev_availability_freelance',
            text: 'When do you prefer to work?',
            subtitle: 'Choose your preferred working hours',
            options: [
              const QuestionOption(
                id: 'fixed',
                title: 'Fixed Schedule',
                subtitle: 'Same hours every day',
                icon: Icons.access_time,
              ),
              const QuestionOption(
                id: 'flexible',
                title: 'Flexible Hours',
                subtitle: 'Different hours each day',
                icon: Icons.schedule,
              ),
            ],
          ),
        ];
      }

      // Fixed schedule follow-up question
      if (answers['dev_availability_freelance'] == 'fixed' &&
          !answers.containsKey('fixed_hours_freelance_developer')) {
        return [
          Question(
            id: 'fixed_hours_freelance_developer',
            text: 'What are your preferred working hours?',
            subtitle: 'Select your daily schedule',
            options: [
              const QuestionOption(
                id: 'morning',
                title: '6 AM - 2 PM',
                subtitle: 'Early bird schedule',
                icon: Icons.wb_sunny,
              ),
              const QuestionOption(
                id: 'day',
                title: '9 AM - 5 PM',
                subtitle: 'Standard business hours',
                icon: Icons.schedule,
              ),
              const QuestionOption(
                id: 'evening',
                title: '2 PM - 10 PM',
                subtitle: 'Evening schedule',
                icon: Icons.nights_stay,
              ),
            ],
          ),
        ];
      }

      // Add the communication question if fixed hours are set
      if (answers['dev_availability_freelance'] == 'fixed' &&
          answers.containsKey('fixed_hours_freelance_developer') &&
          !answers.containsKey('dev_communication')) {
        return [
          Question(
            id: 'dev_communication',
            text: 'How do you prefer to communicate?',
            subtitle: 'This helps schedule meetings and focus time',
            options: [
              const QuestionOption(
                id: 'async',
                title: 'Asynchronous',
                subtitle: 'Prefer email and delayed responses',
                icon: Icons.mail,
              ),
              const QuestionOption(
                id: 'sync',
                title: 'Synchronous',
                subtitle: 'Prefer immediate communication',
                icon: Icons.chat,
              ),
            ],
          ),
        ];
      }
    }

    // Common question.
    if (answers['dev_availability_freelance'] == 'fixed' &&
        answers.containsKey('fixed_hours_freelance_developer') &&
        answers.containsKey('dev_communication')) {
      return [
        Question(
          id: 'dev_deep_work_hours',
          text: 'How many hours of deep work do you want per day?',
          subtitle: 'Choose your preferred deep work duration',
          options: [
            const QuestionOption(
              id: 'low',
              title: '2-3 Hours',
              subtitle: 'Light focus sessions throughout the day',
              icon: Icons.hourglass_empty,
            ),
            const QuestionOption(
              id: 'medium',
              title: '4-5 Hours',
              subtitle: 'Balanced deep work periods',
              icon: Icons.laptop_mac,
            ),
            const QuestionOption(
              id: 'high',
              title: '6+ Hours',
              subtitle: 'Extended deep work sessions',
              icon: Icons.hourglass_full,
            ),
          ],
        )
      ];
    }
    return [];
  }

  @override
  bool isComplete(Map<String, String> answers) {
    final requiredFields = ['dev_employment'];

    // Add company-specific required fields
    if (answers['dev_employment'] == 'company') {
      requiredFields.add('dev_workHours');
      requiredFields.add('meeting_frequency_for_company_developers');
    }

    // Add freelance-specific required fields
    if (answers['dev_employment'] == 'freelance') {
      requiredFields.add('dev_availability_freelance');
      requiredFields.add('dev_communication');
      // Add fixed schedule requirement
      if (answers['dev_availability_freelance'] == 'fixed') {
        requiredFields.add('fixed_hours_freelance_developer');
      }
    }

    return requiredFields.every(answers.containsKey);
  }
}
