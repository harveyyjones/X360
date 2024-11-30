// screens/schedule_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:planner_ai/models/schedule_task.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner_ai/providers/schedule_provider.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  final List<ScheduleTask>? tasks;

  const ScheduleScreen([this.tasks, Key? key]) : super(key: key);

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  @override
  void initState() {
    super.initState();
    // Only load from cache if no tasks were provided
    if (widget.tasks == null || widget.tasks!.isEmpty) {
      ref.read(scheduleProvider.notifier).loadSchedule(
            DateTime.now(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(scheduleProvider);

    return Scaffold(
      backgroundColor: Color(0xFF1A1A1A), // Dark background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Today\'s Schedule',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () {
              // Share functionality
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE').format(DateTime.now()),
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  DateFormat('MMMM d').format(DateTime.now()),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Timeline
          Expanded(
            child: scheduleAsync.when(
              data: (schedule) {
                final tasksToShow = widget.tasks?.isNotEmpty == true
                    ? widget.tasks!
                    : schedule?.tasks ?? [];
                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  itemCount: tasksToShow.length,
                  itemBuilder: (context, index) {
                    final task = tasksToShow[index];
                    final isCompleted =
                        schedule?.completionStatus[task.taskName] ?? false;

                    return TimelineTask(
                      task: task,
                      isFirst: index == 0,
                      isLast: index == tasksToShow.length - 1,
                      isCompleted: isCompleted,
                      onCompletionToggle: (completed) {
                        ref
                            .read(scheduleProvider.notifier)
                            .toggleTaskCompletion(task.taskName);
                      },
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.white70),
              ),
              error: (error, _) => Center(
                child: Text(
                  'Error: $error',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TimelineTask extends StatelessWidget {
  final ScheduleTask task;
  final bool isFirst;
  final bool isLast;
  final bool isCompleted;
  final Function(bool)? onCompletionToggle;

  const TimelineTask({
    required this.task,
    this.isFirst = false,
    this.isLast = false,
    this.isCompleted = false,
    this.onCompletionToggle,
  });

  Color _getEnergyColor(String energyRequired) {
    switch (energyRequired) {
      case 'high':
        return Color(0xFFFF6B6B);
      case 'medium':
        return Color(0xFFFFD93D);
      case 'low':
        return Color(0xFF4ECDC4);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line and dot
          Column(
            children: [
              if (!isFirst)
                Container(
                  width: 2,
                  height: 30,
                  color: Colors.grey.withOpacity(0.3),
                ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getEnergyColor(task.energyRequired),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 2,
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 100,
                  color: Colors.grey.withOpacity(0.3),
                ),
            ],
          ),

          // Task Card
          Expanded(
            child: GestureDetector(
              onTap: () => onCompletionToggle?.call(!isCompleted),
              child: Container(
                margin: EdgeInsets.only(left: 20, bottom: 20),
                decoration: BoxDecoration(
                  color: Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCompleted
                        ? Colors.green.withOpacity(0.3)
                        : Colors.white.withOpacity(0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Time
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${task.startTime} - ${task.endTime}',
                              style: GoogleFonts.dmMono(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(height: 12),

                          // Task Name
                          Text(
                            task.taskName,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8),

                          // Priority and Energy Tags
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      task.getPriorityColor().withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  task.priority
                                      .replaceAll('_', ' ')
                                      .toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    color: task.getPriorityColor(),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getEnergyColor(task.energyRequired)
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${task.energyRequired.toUpperCase()} ENERGY',
                                  style: GoogleFonts.poppins(
                                    color: _getEnergyColor(task.energyRequired),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Break Indicator
                          if (task.breakAfter)
                            Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.coffee,
                                    color: Colors.white54,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Break scheduled after this task',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isCompleted)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 24,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
