// services/question/base_question_service.dart
import 'package:planner_ai/models/question.dart';
import 'package:planner_ai/services/question/developer_question_service.dart';
import 'package:planner_ai/services/question/student_question_service.dart';

abstract class BaseQuestionService {
  List<Question> getInitialQuestions();
  List<Question> getNextQuestions(Map<String, String> answers);
  bool isComplete(Map<String, String> answers);
}

// services/question/question_service_factory.dart
class QuestionServiceFactory {
  static BaseQuestionService getService(String occupation) {
    return switch (occupation) {
      'developer' => DeveloperQuestionService(),
      'student' => StudentQuestionService(),
      _ => throw Exception('Unknown occupation type: $occupation'),
    };
  }
}
