import 'package:planner_ai/models/schedule_task.dart';

class StoredSchedule {
  final DateTime date;
  final List<ScheduleTask> tasks;
  final Map<String, bool> completionStatus;

  StoredSchedule({
    required this.date,
    required this.tasks,
    Map<String, bool>? completionStatus,
  }) : this.completionStatus = completionStatus ?? {};

  factory StoredSchedule.fromJson(Map<String, dynamic> json) {
    return StoredSchedule(
      date: DateTime.parse(json['date']),
      tasks: (json['tasks'] as List)
          .map((taskJson) => ScheduleTask.fromJson(taskJson))
          .toList(),
      completionStatus: Map<String, bool>.from(json['completionStatus'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'tasks': tasks.map((task) => task.toJson()).toList(),
        'completionStatus': completionStatus,
      };

  StoredSchedule copyWith({
    DateTime? date,
    List<ScheduleTask>? tasks,
    Map<String, bool>? completionStatus,
  }) {
    return StoredSchedule(
      date: date ?? this.date,
      tasks: tasks ?? this.tasks,
      completionStatus: completionStatus ?? this.completionStatus,
    );
  }
}
