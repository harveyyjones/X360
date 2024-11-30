// widgets/task_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:planner_ai/app_theme.dart';
import 'package:planner_ai/models/schedule_task.dart';

class TaskCard extends StatelessWidget {
  final ScheduleTask task;
  final Function(bool) onCompleted;
  final bool isFirst;
  final bool isLast;
  final bool isCompleted;

  const TaskCard({
    Key? key,
    required this.task,
    required this.onCompleted,
    required this.isCompleted,
    this.isFirst = false,
    this.isLast = false,
  }) : super(key: key);

  Color _getEnergyColor(String energyRequired) {
    switch (energyRequired.toLowerCase()) {
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
          _buildTimeline(),

          // Task Content
          Expanded(
            child: _buildTaskContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return Column(
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
    );
  }

  Widget _buildTaskContent() {
    return Container(
      margin: EdgeInsets.only(left: 20, bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => onCompleted(!isCompleted),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time Badge
              _buildTimeBadge(),
              SizedBox(height: 12),

              // Task Name
              _buildTaskName(),
              SizedBox(height: 8),

              // Tags Row
              _buildTagsRow(),

              // Break Indicator
              if (task.breakAfter) _buildBreakIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
    );
  }

  Widget _buildTaskName() {
    return Row(
      children: [
        Expanded(
          child: Text(
            task.taskName,
            style: GoogleFonts.poppins(
              color: isCompleted ? Colors.white54 : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
        Checkbox(
          value: isCompleted,
          onChanged: (value) => onCompleted(value ?? false),
          fillColor: MaterialStateProperty.resolveWith(
            (states) => _getEnergyColor(task.energyRequired),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsRow() {
    return Row(
      children: [
        _buildTag(
          text: task.priority.replaceAll('_', ' ').toUpperCase(),
          color: task.getPriorityColor(),
        ),
        SizedBox(width: 8),
        _buildTag(
          text: '${task.energyRequired.toUpperCase()} ENERGY',
          color: _getEnergyColor(task.energyRequired),
        ),
      ],
    );
  }

  Widget _buildTag({required String text, required Color color}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBreakIndicator() {
    return Padding(
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
    );
  }
}
