import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner_ai/models/schedule_task.dart';
import 'package:planner_ai/providers/existing_preferences_provider.dart';
import 'package:planner_ai/services/preferences_factory.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/stored_schedule.dart';
import '../services/gemini_service.dart';
import '../models/preferences/base_preferences.dart';

class LoadingState {
  final bool isLoading;
  final String message;
  final String operation;

  const LoadingState({
    this.isLoading = false,
    this.message = '',
    this.operation = '',
  });
}

final loadingStateProvider = StateProvider<LoadingState>((ref) {
  return const LoadingState();
});

final scheduleProvider =
    StateNotifierProvider<ScheduleNotifier, AsyncValue<StoredSchedule?>>((ref) {
  final preferences = ref.watch(preferencesProvider);

  final notifier = ScheduleNotifier(ref);

  if (preferences != null) {
    Future.microtask(() {
      notifier.loadSchedule(DateTime.now(), preferences);
    });
  }

  return notifier;
});

class ScheduleNotifier extends StateNotifier<AsyncValue<StoredSchedule?>> {
  final _geminiService = GeminiService();
  final Ref ref;

  ScheduleNotifier(this.ref) : super(const AsyncValue.data(null));

  void _updateLoadingState(bool isLoading,
      {String message = '', String operation = ''}) {
    ref.read(loadingStateProvider.notifier).state = LoadingState(
      isLoading: isLoading,
      message: message,
      operation: operation,
    );
  }

  Future<void> loadSchedule(
      [DateTime? date, BasePreferences? preferences]) async {
    if (!mounted) {
      state = const AsyncValue.loading();
    }

    try {
      final targetDate = date ?? DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      final key = 'schedule_${targetDate.toIso8601String().split('T')[0]}';
      final cached = prefs.getString(key);

      if (cached != null) {
        if (!mounted) return;
        state = AsyncValue.data(StoredSchedule.fromJson(jsonDecode(cached)));
        return;
      }

      if (_isToday(targetDate)) {
        if (preferences == null) {
          final prefsKey = 'last_preferences';
          final savedPrefs = prefs.getString(prefsKey);
          if (savedPrefs != null) {
            final prefsMap = jsonDecode(savedPrefs) as Map<String, dynamic>;
            preferences = PreferencesFactory.createPreferences(
              Map<String, String>.from(prefsMap),
            );
          }
        }

        if (preferences != null) {
          final tasks = await _geminiService.generateSchedule([], preferences);
          final schedule = StoredSchedule(date: targetDate, tasks: tasks);
          await prefs.setString(key, jsonEncode(schedule.toJson()));

          await prefs.setString(
              'last_preferences', jsonEncode(preferences.toMap()));

          if (!mounted) return;
          state = AsyncValue.data(schedule);
        } else {
          if (!mounted) return;
          state = const AsyncValue.data(null);
        }
      } else {
        if (!mounted) return;
        state = const AsyncValue.data(null);
      }
    } catch (error, stackTrace) {
      if (!mounted) return;
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> toggleTaskCompletion(String taskName) async {
    final currentState = state.value;
    if (currentState == null) return;

    try {
      final newStatus = Map<String, bool>.from(currentState.completionStatus);
      newStatus[taskName] = !(newStatus[taskName] ?? false);

      final newSchedule = currentState.copyWith(completionStatus: newStatus);

      // Update cache
      final prefs = await SharedPreferences.getInstance();
      final key =
          'schedule_${currentState.date.toIso8601String().split('T')[0]}';
      await prefs.setString(key, jsonEncode(newSchedule.toJson()));

      if (!mounted) return;
      state = AsyncValue.data(newSchedule);
    } catch (error, stackTrace) {
      if (!mounted) return;
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addTask(
      ScheduleTask newTask, BasePreferences? preferences) async {
    final currentState = state.value;
    if (currentState == null) {
      await loadSchedule(DateTime.now(), preferences);
      return;
    }

    if (!mounted) return;
    _updateLoadingState(true,
        message: 'Adding new task...', operation: 'adding');

    try {
      // First add the new task to the existing tasks
      final updatedTasks = [...currentState.tasks, newTask];
      final newSchedule = currentState.copyWith(tasks: updatedTasks);

      // Show immediate update
      state = AsyncValue.data(newSchedule);

      if (preferences != null) {
        _updateLoadingState(true,
            message: 'Optimizing schedule...', operation: 'generating');
        // Generate a new schedule with updated task order, passing completion status
        final reorderedTasks = await _geminiService.generateSchedule(
          updatedTasks,
          preferences,
          currentState.completionStatus, // Pass current completion status
        );
        final finalSchedule = newSchedule.copyWith(tasks: reorderedTasks);
        await _saveSchedule(finalSchedule);

        if (!mounted) return;
        state = AsyncValue.data(finalSchedule);
      } else {
        await _saveSchedule(newSchedule);
      }
    } catch (error, stackTrace) {
      if (!mounted) return;
      state = AsyncValue.error(error, stackTrace);
    } finally {
      _updateLoadingState(false);
    }
  }

  Future<void> reorderTasks(
      int oldIndex, int newIndex, BasePreferences? preferences) async {
    final currentState = state.value;
    if (currentState == null || !mounted) return;

    _updateLoadingState(true,
        message: 'Reordering tasks...', operation: 'reordering');

    try {
      // Create new list with the new order
      final tasks = List<ScheduleTask>.from(currentState.tasks);
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final task = tasks.removeAt(oldIndex);
      tasks.insert(newIndex, task);

      if (preferences != null) {
        final reorderedTasks = await _geminiService.updateScheduleTimes(
          originalSchedule: currentState, // This contains the previous order
          newTaskOrder: tasks,
          preferences: preferences,
          completionStatus: currentState.completionStatus,
        );

        // Show immediate reorder
        final newSchedule = currentState.copyWith(tasks: reorderedTasks);
        state = AsyncValue.data(newSchedule);

        if (preferences != null) {
          _updateLoadingState(true,
              message: 'Updating schedule times...', operation: 'generating');
          // Pass the original schedule as context and the new task order
          final reorderedTasks = await _geminiService.updateScheduleTimes(
            originalSchedule: currentState,
            newTaskOrder: tasks,
            preferences: preferences,
            completionStatus: currentState.completionStatus,
          );
          final finalSchedule = newSchedule.copyWith(tasks: reorderedTasks);
          await _saveSchedule(finalSchedule);

          if (!mounted) return;
          state = AsyncValue.data(finalSchedule);
        } else {
          await _saveSchedule(newSchedule);
        }
      }
    } catch (error, stackTrace) {
      if (!mounted) return;
      state = AsyncValue.error(error, stackTrace);
    } finally {
      _updateLoadingState(false);
    }
  }

  // Helper method to save schedule to SharedPreferences
  Future<void> _saveSchedule(StoredSchedule schedule) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'schedule_${schedule.date.toIso8601String().split('T')[0]}';
    await prefs.setString(key, jsonEncode(schedule.toJson()));
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

// Add this class at the top of schedule_provider.dart
class ScheduleLoadingState {
  final bool isLoading;
  final String? operation; // e.g., "adding", "reordering", "generating"
  final String? message;

  const ScheduleLoadingState({
    this.isLoading = false,
    this.operation,
    this.message,
  });

  ScheduleLoadingState copyWith({
    bool? isLoading,
    String? operation,
    String? message,
  }) {
    return ScheduleLoadingState(
      isLoading: isLoading ?? this.isLoading,
      operation: operation ?? this.operation,
      message: message ?? this.message,
    );
  }
}

class ScheduleState {
  final AsyncValue<StoredSchedule?> schedule;
  final LoadingState loadingState;

  const ScheduleState({
    this.schedule = const AsyncValue.data(null),
    this.loadingState = const LoadingState(),
  });

  ScheduleState copyWith({
    AsyncValue<StoredSchedule?>? schedule,
    LoadingState? loadingState,
  }) {
    return ScheduleState(
      schedule: schedule ?? this.schedule,
      loadingState: loadingState ?? this.loadingState,
    );
  }
}
