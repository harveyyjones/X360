// models/question.dart
import 'package:flutter/material.dart';

class Question {
  final String id;
  final String text;
  final String subtitle;
  final List<QuestionOption> options;

  Question({
    required this.id,
    required this.text,
    required this.subtitle,
    required this.options,
  });
}

class QuestionOption {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;

  const QuestionOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
