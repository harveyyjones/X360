import 'dart:convert';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:planner_ai/models/preferences/base_preferences.dart';
import 'package:planner_ai/models/preferences/developer_preferences.dart';
import 'package:planner_ai/models/preferences/student_preferences.dart';
import 'package:planner_ai/models/schedule_task.dart';
import 'package:planner_ai/models/stored_schedule.dart';

class GeminiService {
  final gemini = Gemini.instance;

  String _generatePrompt(List<ScheduleTask> tasks, BasePreferences prefs,
      Map<String, bool> completionStatus) {
    final tasksInfo = tasks.map((task) {
      final isCompleted = completionStatus[task.taskName] ?? false;
      return {
        'taskName': task.taskName,
        'priority': task.priority,
        'energyRequired': task.energyRequired,
        'startTime': task.startTime,
        'endTime': task.endTime,
        'isCompleted': isCompleted,
        'order': task.order,
      };
    }).toList();

    return switch (prefs) {
      DeveloperPreferences dev => '''
        You are a scheduling AI assistant. Create a daily schedule in JSON format.
        Developer Profile:
        - Software Developer (${dev.employmentType ?? 'Freelance'})
        - ${dev.employmentType == 'company' ? 'Works ${dev.workHours}' : 'Flexible hours'}
        - Communication style: ${dev.communicationStyle}

        Rules:
        1. Use 24-hour format (HH:mm)
        2. Priority levels: "very_important", "middle", "not_important"
        3. Energy levels: "high", "medium", "low"
        4. MAINTAIN THE TIME SLOTS OF COMPLETED TASKS - this is critical
        5. Schedule uncompleted tasks around completed ones
        6. ${dev.communicationStyle == 'async' ? 'Group meetings together for async communication' : 'Spread meetings throughout for sync communication'}
        7. Never leave a task without a time slot and never leave a time slot empty. Make assumptions if necessary.
        8. If there is any conflict in time slots (e. g. two tasks with the same start time), prioritize the task with the highest priority.
        9. If there is any conflict in time slots (e. g one of the task's start time is earlier than the other task's end time but the order number is greater, by keeping the order change the time slots of the all tasks keeping the given time range of each task).
        10. NEVER return null or empty times. If unsure, schedule after the latest task's end time.

        If the tasks with completion status are provided, use them to maintain the time slots of completed tasks, 
        In another words, if the task is completed, do not change its start and end time and while scheduling other tasks, do not put them in the completed task time slot. Also include the completed tasks in the response as they were provided.
And make the every individual task with the same json format.
        Below is the list of tasks.:
        ${jsonEncode(tasksInfo)}

        JSON format should be exactly like below without any other text or quotes:
        {
        "tasks": [
        {
        "taskName": "Task description",
        "priority": "very_important/middle/not_important",
        "startTime": "HH:mm",
        "endTime": "HH:mm",
        "energyRequired": "high/medium/low",
        "breakAfter": boolean,
        "order": number,
        "isCompleted": boolean
        
        }
        ]
        }
      ''',
      _ => throw Exception('Unknown preference type'),
    };
  }

  Future<List<ScheduleTask>> generateSchedule(
      List<ScheduleTask> tasks, BasePreferences preferences,
      [Map<String, bool> completionStatus = const {}]) async {
    try {
      final response = await gemini
          .text(_generatePrompt(tasks, preferences, completionStatus));
      if (response?.output == null) return [];

      String jsonStr = response!.output!.trim();

      // Print raw response
      print('Raw Gemini response:\n${response.output}');

      // Clean up JSON response
      if (jsonStr.startsWith("'''JSON")) {
        jsonStr = jsonStr.substring(7).trim(); // Remove '''JSON
      } else if (jsonStr.startsWith("'''")) {
        jsonStr = jsonStr.substring(3).trim(); // Remove triple single quotes
      } else if (jsonStr.startsWith('```JSON')) {
        jsonStr = jsonStr.substring(7).trim(); // Remove ```JSON
      } else if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.substring(3).trim(); // Remove triple backticks
      }

      if (jsonStr.endsWith("'''")) {
        jsonStr = jsonStr.substring(0, jsonStr.length - 3).trim();
      } else if (jsonStr.endsWith('```')) {
        jsonStr = jsonStr.substring(0, jsonStr.length - 3).trim();
      }

      try {
        final jsonData = jsonDecode(jsonStr) as Map<String, dynamic>;
        final scheduledTasks = (jsonData['tasks'] as List)
            .map((task) => ScheduleTask.fromJson(task as Map<String, dynamic>))
            .toList();

        // Preserve completion status
        return scheduledTasks;
      } catch (e) {
        print('JSON parsing error: $e\nRaw JSON: $jsonStr');
        return [];
      }
    } catch (e) {
      print('Gemini service error: $e');
      return [];
    }
  }

  String _generateUpdateTimesPrompt(StoredSchedule originalSchedule,
      List<ScheduleTask> newTaskOrder, BasePreferences prefs) {
    // Get earliest start time from original schedule
    final firstTaskStart = originalSchedule.tasks
        .map((t) => _parseTime(t.startTime))
        .reduce((a, b) => a.isBefore(b) ? a : b);

    // Get the previous order with task durations
    final previousOrder = originalSchedule.tasks.map((task) {
      final duration = _calculateDuration(task.startTime, task.endTime);
      return {
        'taskName': task.taskName,
        'priority': task.priority,
        'energyRequired': task.energyRequired,
        'startTime': task.startTime,
        'endTime': task.endTime,
        'duration': duration,
        'isCompleted':
            originalSchedule.completionStatus[task.taskName] ?? false,
      };
    }).toList();

    // Get the new desired order
    final desiredOrder = newTaskOrder.map((task) {
      final duration = _calculateDuration(task.startTime, task.endTime);
      return {
        'taskName': task.taskName,
        'duration': duration,
        'isCompleted':
            originalSchedule.completionStatus[task.taskName] ?? false,
      };
    }).toList();

    return '''
      You are a scheduling assistant. RECALCULATE ALL TIMES based on the new task order.
      
      Start scheduling from ${_formatTime(firstTaskStart)}.
      
      PREVIOUS SCHEDULE:
      ${jsonEncode(previousOrder)}

      NEW ORDER (NEEDS NEW TIMES):
      ${jsonEncode(desiredOrder)}
      
      EXAMPLE OF WHAT TO DO:
      If tasks A(30min), B(60min), C(45min) are reordered from ABC to CAB:
      - C should start at the earliest time
      - A should start immediately after C ends
      - B should start immediately after A ends
      Each task keeps its original duration but gets new start/end times.

      CRITICAL RULES:
      1. Start with the first task at ${_formatTime(firstTaskStart)}
      2. Each subsequent task starts immediately after the previous one ends
      3. Keep original duration of each task
      4. Completed tasks (if any) keep their original times
      5. Schedule uncompleted tasks around completed ones
      6. NO GAPS between tasks (unless working around completed tasks)
      7. NO OVERLAPPING times allowed
      8. NEVER return null or empty times. If unsure about a task's time, schedule it after the latest task's end time.
      
      REQUIRED: Calculate new start/end times for EVERY task based on the new order.
      
      Return ONLY JSON with updated times:
      {
        "tasks": [
          {
            "taskName": "Task description",
            "priority": "priority_level",
            "startTime": "HH:mm",
            "endTime": "HH:mm",
            "energyRequired": "energy_level",
            "breakAfter": boolean,
            "order": number,
            "isCompleted": boolean
          }
        ]
      }
    ''';
  }

  // Helper method to format DateTime to HH:mm
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Helper method to calculate duration in minutes
  int _calculateDuration(String startTime, String endTime) {
    final start = _parseTime(startTime);
    final end = _parseTime(endTime);
    return end.difference(start).inMinutes;
  }

  // Helper method to parse time string
  DateTime _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  Future<List<ScheduleTask>> updateScheduleTimes({
    required StoredSchedule originalSchedule,
    required List<ScheduleTask> newTaskOrder,
    required BasePreferences preferences,
    required Map<String, bool> completionStatus,
  }) async {
    try {
      // Print initial comparison
      print('\n=== INITIAL TASK ORDERS ===');
      print(
          'Original order: ${originalSchedule.tasks.map((t) => t.taskName).toList()}');
      print('New order: ${newTaskOrder.map((t) => t.taskName).toList()}');
      print('=== END INITIAL ORDERS ===\n');

      // Only proceed if the order has actually changed
      bool orderChanged = false;
      for (int i = 0; i < originalSchedule.tasks.length; i++) {
        if (originalSchedule.tasks[i].taskName != newTaskOrder[i].taskName) {
          orderChanged = true;
          break;
        }
      }

      if (!orderChanged) {
        print('Order unchanged, returning original tasks');
        return newTaskOrder;
      }

      // Generate and log the prompt
      final prompt = _generateUpdateTimesPrompt(
          originalSchedule, newTaskOrder, preferences);
      print('\n=== SENDING PROMPT TO GEMINI ===');
      print(prompt);
      print('=== END PROMPT ===\n');

      final response = await gemini.text(prompt);
      if (response?.output == null) {
        print('ERROR: Gemini returned null response');
        return newTaskOrder;
      }

      print('\n=== RAW GEMINI RESPONSE ===');
      print(response?.output);
      print('=== END RESPONSE ===\n');

      String jsonStr = response!.output!.trim();
      // Clean up JSON response
      if (jsonStr.startsWith("'''JSON") ||
          jsonStr.startsWith("'''") ||
          jsonStr.startsWith('```JSON') ||
          jsonStr.startsWith('```')) {
        jsonStr = jsonStr.substring(jsonStr.indexOf('{'));
      }
      if (jsonStr.endsWith("'''") || jsonStr.endsWith('```')) {
        jsonStr = jsonStr.substring(0, jsonStr.lastIndexOf('}') + 1).trim();
      }

      print('\n=== CLEANED JSON STRING ===');
      print(jsonStr);
      print('=== END JSON STRING ===\n');

      try {
        final jsonData = jsonDecode(jsonStr) as Map<String, dynamic>;
        final updatedTasks = (jsonData['tasks'] as List)
            .map((task) => ScheduleTask.fromJson(task as Map<String, dynamic>))
            .toList();

        // Validate the order matches the requested order
        bool orderMatches = true;
        for (int i = 0; i < newTaskOrder.length; i++) {
          if (updatedTasks[i].taskName != newTaskOrder[i].taskName) {
            orderMatches = false;
            print('Order mismatch at position $i:');
            print('Expected: ${newTaskOrder[i].taskName}');
            print('Got: ${updatedTasks[i].taskName}');
            break;
          }
        }

        print('\n=== FINAL TASK ORDER COMPARISON ===');
        print(
            'Requested order: ${newTaskOrder.map((t) => t.taskName).toList()}');
        print(
            'Updated order:   ${updatedTasks.map((t) => t.taskName).toList()}');
        print('Order matches: $orderMatches');
        print('=== END COMPARISON ===\n');

        // Return the updated tasks only if the order matches
        return orderMatches ? updatedTasks : newTaskOrder;
      } catch (e) {
        print('\n=== JSON PARSING ERROR ===');
        print('Error: $e');
        print('Raw JSON: $jsonStr');
        print('=== END ERROR ===\n');
        return newTaskOrder;
      }
    } catch (e) {
      print('\n=== GEMINI SERVICE ERROR ===');
      print(e);
      print('=== END ERROR ===\n');
      return newTaskOrder;
    }
  }
}
