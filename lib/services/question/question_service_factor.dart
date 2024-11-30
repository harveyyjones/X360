// services/question/question_service_factory.dart
import 'package:planner_ai/services/question/base_question_service.dart';
import 'package:planner_ai/services/question/developer_question_service.dart';

class QuestionServiceFactory {
  static BaseQuestionService getService(String occupation) {
    return switch (occupation) {
      'developer' => DeveloperQuestionService(),
      _ => throw Exception('Unknown occupation type: $occupation'),
    };
  }
}
