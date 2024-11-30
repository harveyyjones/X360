import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner_ai/models/preferences/base_preferences.dart';
import 'package:planner_ai/providers/existing_preferences_provider.dart';
import 'package:planner_ai/screens/schedule_screens.dart';
import '../models/schedule_task.dart';
import '../providers/schedule_provider.dart';

import 'questions_screen.dart';

class TaskManagementScreen extends ConsumerStatefulWidget {
  const TaskManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TaskManagementScreen> createState() =>
      _TaskManagementScreenState();
}

class _TaskManagementScreenState extends ConsumerState<TaskManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _taskController = TextEditingController();
  String _selectedPriority = 'middle';
  String _selectedEnergy = 'medium';

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(preferencesProvider);
    final scheduleAsync = ref.watch(scheduleProvider);
    final loadingState = ref.watch(loadingStateProvider);

    // If no preferences are set, show setup screen
    if (preferences == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Please set up your preferences first'),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => QuestionsScreen()),
                  );
                },
                child: Text('Setup Preferences'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Tasks'),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_month),
            onPressed: loadingState.isLoading
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ScheduleScreen(),
                      ),
                    );
                  },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildTaskInput(),
              Expanded(
                child: scheduleAsync.when(
                  data: (schedule) {
                    final tasks = schedule?.tasks ?? [];
                    if (tasks.isEmpty) {
                      return Center(
                        child: Text('Add tasks to create your schedule'),
                      );
                    }

                    return ReorderableListView.builder(
                      itemCount: tasks.length,
                      onReorder: loadingState.isLoading
                          ? (_, __) {}
                          : (oldIndex, newIndex) {
                              if (oldIndex != newIndex) {
                                if (oldIndex < newIndex) {
                                  newIndex -= 1;
                                }
                                ref
                                    .read(scheduleProvider.notifier)
                                    .reorderTasks(
                                      oldIndex,
                                      newIndex,
                                      preferences,
                                    );
                              }
                            },
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return _buildTaskCard(task, index);
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Text('Error: $error'),
                  ),
                ),
              ),
            ],
          ),
          if (loadingState.isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            loadingState.message,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: loadingState.isLoading ? null : _showAddTaskDialog,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildTaskInput() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your Tasks',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 8),
              Text(
                'Add tasks using + button and reorder them by drag & drop',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Task'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _taskController,
                decoration: InputDecoration(
                  labelText: 'Task Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a task name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPriority,
                decoration: InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                      value: 'very_important', child: Text('High Priority')),
                  DropdownMenuItem(
                      value: 'middle', child: Text('Medium Priority')),
                  DropdownMenuItem(
                      value: 'not_important', child: Text('Low Priority')),
                ],
                onChanged: (value) {
                  setState(() => _selectedPriority = value!);
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedEnergy,
                decoration: InputDecoration(
                  labelText: 'Energy Required',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'high', child: Text('High Energy')),
                  DropdownMenuItem(
                      value: 'medium', child: Text('Medium Energy')),
                  DropdownMenuItem(value: 'low', child: Text('Low Energy')),
                ],
                onChanged: (value) {
                  setState(() => _selectedEnergy = value!);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _addTask(ref.read(preferencesProvider)!),
            child: Text('Add Task'),
          ),
        ],
      ),
    );
  }

  void _addTask(BasePreferences preferences) {
    if (_formKey.currentState?.validate() ?? false) {
      final newTask = ScheduleTask(
        taskName: _taskController.text,
        priority: _selectedPriority,
        energyRequired: _selectedEnergy,
        order: 0,
      );

      Navigator.pop(context);
      ref.read(scheduleProvider.notifier).addTask(newTask, preferences);
      _taskController.clear();
    }
  }

  Widget _buildTaskCard(ScheduleTask task, int index) {
    final scheduleData = ref.watch(scheduleProvider).value;
    final isCompleted = scheduleData?.completionStatus[task.taskName] ?? false;
    final loadingState = ref.watch(loadingStateProvider);

    return Card(
      key: ValueKey('${task.taskName}_$index'),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          if (task.startTime.isNotEmpty && task.endTime.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Text(
                '${task.startTime} - ${task.endTime}',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ListTile(
            leading: InkWell(
              onTap: loadingState.isLoading
                  ? null
                  : () {
                      ref
                          .read(scheduleProvider.notifier)
                          .toggleTaskCompletion(task.taskName);
                    },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted ? Colors.green : Colors.grey,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(2),
                  child: isCompleted
                      ? Icon(Icons.check, color: Colors.green, size: 20)
                      : SizedBox(width: 20, height: 20),
                ),
              ),
            ),
            title: Text(
              task.taskName,
              style: TextStyle(
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                color: isCompleted ? Colors.grey : null,
              ),
            ),
            subtitle: Row(
              children: [
                Chip(
                  label: Text(task.priority),
                  backgroundColor: _getPriorityColor(task.priority).withOpacity(
                    isCompleted ? 0.5 : 1,
                  ),
                ),
                SizedBox(width: 8),
                Chip(
                  label: Text(task.energyRequired),
                  backgroundColor:
                      _getEnergyColor(task.energyRequired).withOpacity(
                    isCompleted ? 0.5 : 1,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (task.breakAfter)
                  Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Tooltip(
                      message: 'Break after this task',
                      child: Icon(Icons.coffee, color: Colors.brown),
                    ),
                  ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: loadingState.isLoading
                      ? null
                      : () {
                          // Add delete functionality
                        },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTaskIcon(String priority) {
    switch (priority) {
      case 'very_important':
        return Icons.priority_high;
      case 'middle':
        return Icons.arrow_right;
      case 'not_important':
        return Icons.low_priority;
      default:
        return Icons.task;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'very_important':
        return Colors.red.shade100;
      case 'middle':
        return Colors.orange.shade100;
      case 'not_important':
        return Colors.green.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getEnergyColor(String energy) {
    switch (energy) {
      case 'high':
        return Colors.purple.shade100;
      case 'medium':
        return Colors.blue.shade100;
      case 'low':
        return Colors.teal.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }
}
