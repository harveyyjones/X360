// screens/questions_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner_ai/models/question.dart';
import 'package:planner_ai/providers/existing_preferences_provider.dart';
import 'package:planner_ai/services/preferences_factory.dart';

import 'package:planner_ai/services/question/base_question_service.dart';

import 'task_management_screen.dart';

class QuestionsScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends ConsumerState<QuestionsScreen> {
  final PageController _pageController = PageController();
  final Map<String, String> _answers = {};
  late List<Question> _questions;
  int _currentIndex = 0;
  BaseQuestionService? _questionService;

  @override
  void initState() {
    super.initState();
    _questions = [
      Question(
        id: 'occupation',
        text: 'What\'s your role?',
        subtitle: 'Select your primary occupation',
        options: [
          const QuestionOption(
            id: 'developer',
            title: 'Software Developer',
            subtitle: 'Programming & Development',
            icon: Icons.code,
          ),
          const QuestionOption(
            id: 'student',
            title: 'Student',
            subtitle: 'Studying & Learning',
            icon: Icons.school,
          ),
        ],
      ),
    ];
  }

  void _handleOptionSelected(String questionId, String optionId) {
    setState(() {
      // Add debug logging for skipped questions
      for (var q in _questions) {
        if (q.id != questionId && !_answers.containsKey(q.id)) {
          print('Skipped question: ${q.id} without answer'); // Debug print
        }
      }

      _answers[questionId] = optionId;
      print('Selected: $questionId -> $optionId'); // Debug print

      if (questionId == 'occupation') {
        try {
          _questionService = QuestionServiceFactory.getService(optionId);
          _questions = _questionService!.getInitialQuestions();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
          return;
        }
      } else {
        final nextQuestions =
            _questionService?.getNextQuestions(_answers) ?? [];
        if (nextQuestions.isNotEmpty) {
          _questions = nextQuestions;
        }
      }

      if (_currentIndex < _questions.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _currentIndex++;
      }
    });
  }

  bool get _canProceed {
    // Basic validation - must have occupation
    if (!_answers.containsKey('occupation')) return false;

    // Occupation-specific validation
    return switch (_answers['occupation']) {
      'developer' => ['dev_employment', 'dev_workHours', 'dev_communication']
          .every(_answers.containsKey),
      // Add cases for other occupations
      _ => false,
    };
  }

  void _createPreferencesAndNavigate() {
    if (_questionService == null || !_questionService!.isComplete(_answers)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all questions')),
      );
      return;
    }

    try {
      final prefs = PreferencesFactory.createPreferences(_answers);

      // Update global preferences state
      ref.read(preferencesProvider.notifier).updatePreferences(prefs);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const TaskManagementScreen(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressBar(),
            Expanded(child: _buildQuestions()),
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_currentIndex > 0)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                setState(() => _currentIndex--);
              },
            ),
          Expanded(
            child: Text(
              'Setup Your Profile',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: _currentIndex > 0 ? TextAlign.center : TextAlign.start,
            ),
          ),
          Text(
            '${_currentIndex + 1}/${_questions.length}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LinearProgressIndicator(
        value: (_currentIndex + 1) / _questions.length,
        backgroundColor: Colors.grey[200],
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildQuestions() {
    return PageView.builder(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _questions.length,
      onPageChanged: (index) => setState(() => _currentIndex = index),
      itemBuilder: (context, index) => _buildQuestionPage(_questions[index]),
    );
  }

  Widget _buildQuestionPage(Question question) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.text,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            question.subtitle,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: question.options.length,
              itemBuilder: (context, index) =>
                  _buildOptionCard(question.id, question.options[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(String questionId, QuestionOption option) {
    final isSelected = _answers[questionId] == option.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 2 : 1,
      child: ListTile(
        leading: Icon(
          option.icon,
          color: isSelected ? Theme.of(context).primaryColor : null,
        ),
        title: Text(option.title),
        subtitle: Text(option.subtitle),
        selected: isSelected,
        onTap: () => _handleOptionSelected(questionId, option.id),
      ),
    );
  }

  Widget _buildBottomButton() {
    if (_currentIndex != _questions.length - 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: _createPreferencesAndNavigate,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: const Text(
            'Continue',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
