// models/schedule_task.dart (previously model_for_gemini_response.dart)
import 'package:flutter/material.dart';

// Individual task model with properties like time, priority, energy level. If you want to obtain a new data from the Gemini, add the new field to this class first. Also dont forget to add the new field to the `toJson` and `fromJson` methods.
class ScheduleTask {
  final String taskName;
  final String priority;
  final String startTime;
  final String endTime;
  final String energyRequired;
  final bool breakAfter;
  final int order;
  final bool isCompleted;
  ScheduleTask({
    required this.taskName,
    required this.priority,
    this.startTime = '',
    this.endTime = '',
    required this.energyRequired,
    this.breakAfter = false,
    required this.order,
    this.isCompleted = false,
  });

  factory ScheduleTask.fromJson(Map<String, dynamic> json) {
    String? normalizeTimeFormat(String? time) {
      if (time == null) return null;

      // Remove any whitespace
      time = time.trim();

      // If time is already in HH:mm format
      if (RegExp(r'^\d{2}:\d{2}$').hasMatch(time)) {
        return time;
      }

      // If time is in H:mm format
      if (RegExp(r'^\d{1}:\d{2}$').hasMatch(time)) {
        return '0$time';
      }

      // If time includes AM/PM
      if (time.toUpperCase().contains('AM') ||
          time.toUpperCase().contains('PM')) {
        final parts = time.toUpperCase().split(' ');
        final timeParts = parts[0].split(':');
        int hour = int.parse(timeParts[0]);
        final minute = timeParts[1];
        final period = parts[1];

        if (period == 'PM' && hour != 12) {
          hour += 12;
        } else if (period == 'AM' && hour == 12) {
          hour = 0;
        }

        return '${hour.toString().padLeft(2, '0')}:$minute';
      }

      // Return original if no format matches
      return time;
    }

    try {
      return ScheduleTask(
        taskName: json['taskName'] as String? ?? 'Untitled Task',
        priority: json['priority'] as String? ?? 'middle',
        startTime: normalizeTimeFormat(json['startTime'] as String?) ?? '',
        endTime: normalizeTimeFormat(json['endTime'] as String?) ?? '',
        energyRequired: json['energyRequired'] as String? ?? 'medium',
        breakAfter: json['breakAfter'] as bool? ?? false,
        order: json['order'] as int? ?? 0,
        isCompleted: json['isCompleted'] as bool? ?? false,
      );
    } catch (e) {
      print('Error creating ScheduleTask from JSON: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => {
        'taskName': taskName,
        'priority': priority,
        'startTime': startTime,
        'endTime': endTime,
        'energyRequired': energyRequired,
        'breakAfter': breakAfter,
        'order': order,
        'isCompleted': isCompleted,
      };

  ScheduleTask copyWith({
    String? taskName,
    String? priority,
    String? startTime,
    String? endTime,
    String? energyRequired,
    bool? breakAfter,
    int? order,
    bool? isCompleted,
  }) {
    return ScheduleTask(
      taskName: taskName ?? this.taskName,
      priority: priority ?? this.priority,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      energyRequired: energyRequired ?? this.energyRequired,
      breakAfter: breakAfter ?? this.breakAfter,
      order: order ?? this.order,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Color getPriorityColor() {
    switch (priority) {
      case 'very_important':
        return Colors.red.shade400;
      case 'middle':
        return Colors.amber.shade400;
      case 'not_important':
        return Colors.green.shade400;
      default:
        return Colors.grey;
    }
  }
}
