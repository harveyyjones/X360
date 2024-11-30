// services/question/developer_question_service.dart
import 'package:flutter/material.dart';
import 'package:planner_ai/models/question.dart';
import 'package:planner_ai/services/question/base_question_service.dart';

class StudentQuestionService extends BaseQuestionService {
  @override
  List<Question> getInitialQuestions() {
    return [
      Question(
        id: 'deep_work_student',
        text: 'How many hours can you dedicate to focused study?',
        subtitle: 'Choose your ideal deep work duration',
        options: [
          const QuestionOption(
            id: 'light',
            title: '1-2 Hours',
            subtitle: 'Short focused study sessions',
            icon: Icons.hourglass_empty,
          ),
          const QuestionOption(
            id: 'moderate',
            title: '3-4 Hours',
            subtitle: 'Balanced study periods',
            icon: Icons.hourglass_bottom,
          ),
          const QuestionOption(
            id: 'intensive',
            title: '5+ Hours',
            subtitle: 'Extended study sessions',
            icon: Icons.hourglass_full,
          ),
        ],
      ),
    ];
  }

  @override
  List<Question> getNextQuestions(Map<String, String> answers) {
    if (!answers.containsKey('time_preference_student')) {
      return [
        Question(
          id: 'time_preference_student',
          text: 'When are you most productive for studying?',
          subtitle: 'Select your peak performance time',
          options: [
            const QuestionOption(
              id: 'morning',
              title: 'Morning Person',
              subtitle: 'Best focus before noon',
              icon: Icons.wb_sunny,
            ),
            const QuestionOption(
              id: 'afternoon',
              title: 'Afternoon Person',
              subtitle: 'Best focus mid-day',
              icon: Icons.wb_twilight,
            ),
            const QuestionOption(
              id: 'evening',
              title: 'Night Owl',
              subtitle: 'Best focus after sunset',
              icon: Icons.nights_stay,
            ),
          ],
        ),
      ];
    }

    if (!answers.containsKey('environment_student')) {
      return [
        Question(
          id: 'environment_student',
          text: 'Where do you prefer to study?',
          subtitle: 'Choose your ideal study environment',
          options: [
            const QuestionOption(
              id: 'library',
              title: 'Library',
              subtitle: 'Quiet and structured environment',
              icon: Icons.local_library,
            ),
            const QuestionOption(
              id: 'home',
              title: 'Home',
              subtitle: 'Comfortable and familiar setting',
              icon: Icons.home,
            ),
            const QuestionOption(
              id: 'cafe',
              title: 'Café',
              subtitle: 'Ambient background noise',
              icon: Icons.coffee,
            ),
          ],
        ),
      ];
    }

    return [];
  }

  @override
  bool isComplete(Map<String, String> answers) {
    final requiredFields = [
      'deep_work_student',
      'time_preference_student',
      'environment_student',
    ];

    return requiredFields.every(answers.containsKey);
  }
}
