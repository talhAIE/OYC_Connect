import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/classes_providers.dart';
import '../../data/models/weekly_schedule_model.dart';

class ClassesSchedulePage extends ConsumerStatefulWidget {
  const ClassesSchedulePage({super.key});

  @override
  ConsumerState<ClassesSchedulePage> createState() =>
      _ClassesSchedulePageState();
}

class _ClassesSchedulePageState extends ConsumerState<ClassesSchedulePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => false; // Don't keep alive to ensure fresh data

  @override
  void initState() {
    super.initState();
    // Invalidate providers on page load to ensure fresh data
    Future.microtask(() {
      ref.invalidate(weeklySchedulesProvider);
      ref.invalidate(quranSchedulesProvider);
    });
  }

  Future<void> _refreshData() async {
    ref.invalidate(weeklySchedulesProvider);
    ref.invalidate(quranSchedulesProvider);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final weeklyAsync = ref.watch(weeklySchedulesProvider);
    final quranAsync = ref.watch(quranSchedulesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: const Color(0xFF1B5E20),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compact Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.school,
                        color: Color(0xFF1B5E20),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Weekly Classes',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Compact Info Banner
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF1976D2).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFF1976D2),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'All classes held between Maghrib & Isha, unless stated otherwise.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[900],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Weekly Schedule Section
                Text(
                  'WEEKLY SCHEDULE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black.withAlpha(185),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),

                weeklyAsync.when(
                  data: (schedules) =>
                      _buildCompactScheduleList(schedules, type: 'weekly'),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                ),

                const SizedBox(height: 20),

                // Qur'an Classes Section
                Text(
                  "QUR'AN CLASSES",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black.withAlpha(185),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),

                quranAsync.when(
                  data: (schedules) =>
                      _buildCompactScheduleList(schedules, type: 'quran'),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactScheduleList(
    List<WeeklyScheduleModel> schedules, {
    required String type,
  }) {
    if (schedules.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'No ${type == 'weekly' ? 'weekly' : "Qur'an"} classes scheduled yet.',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      );
    }

    // Group schedules by class+teacher+time to merge day ranges
    final grouped = _groupSchedules(schedules);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: grouped.map((group) {
        return _buildCompactScheduleCard(group, type: type);
      }).toList(),
    );
  }

  List<_ScheduleGroup> _groupSchedules(List<WeeklyScheduleModel> schedules) {
    final Map<String, _ScheduleGroup> groups = {};

    for (var schedule in schedules) {
      // Create a unique key based on class, teacher, and time
      final key =
          '${schedule.classId}_${schedule.teacherId}_${schedule.startTime}_${schedule.endTime}';

      if (groups.containsKey(key)) {
        groups[key]!.days.add(schedule.dayOfWeek);
      } else {
        groups[key] = _ScheduleGroup(
          className: schedule.className,
          teacherName: schedule.teacherName,
          startTime: schedule.startTime,
          endTime: schedule.endTime,
          days: [schedule.dayOfWeek],
        );
      }
    }

    // Sort days within each group
    for (var group in groups.values) {
      group.days.sort();
    }

    return groups.values.toList();
  }

  Widget _buildCompactScheduleCard(
    _ScheduleGroup group, {
    required String type,
  }) {
    final iconColor = type == 'quran'
        ? const Color(0xFF6A1B9A)
        : const Color(0xFF1B5E20);
    final bgColor = type == 'quran'
        ? const Color(0xFFF3E5F5)
        : const Color(0xFFE8F5E9);
    final icon = type == 'quran' ? Icons.menu_book : Icons.calendar_today;
    final hasTime = group.startTime != null && group.endTime != null;

    // Format day range
    final dayDisplay = _formatDayRange(group.days);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day range
                Text(
                  dayDisplay,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),

                // Class name and teacher in one line
                Row(
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                          children: [
                            TextSpan(
                              text: group.className ?? 'Unknown Class',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (group.teacherName != null) ...[
                              TextSpan(
                                text: ' (${group.teacherName})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black.withAlpha(205),
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Time badge
          if (hasTime)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time, size: 13, color: iconColor),
                  const SizedBox(width: 4),
                  Text(
                    '${group.startTime}–${group.endTime}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: iconColor,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDayRange(List<int> days) {
    if (days.isEmpty) return '';
    if (days.length == 1) return _getDayName(days[0]);

    // Check if days are consecutive
    bool isConsecutive = true;
    for (int i = 1; i < days.length; i++) {
      if (days[i] != days[i - 1] + 1) {
        isConsecutive = false;
        break;
      }
    }

    if (isConsecutive) {
      // Show as range: Mon–Wed
      return '${_getDayAbbr(days.first)}–${_getDayAbbr(days.last)}';
    } else {
      // Show individual days: Tue & Thu
      return days.map((d) => _getDayAbbr(d)).join(' & ');
    }
  }

  String _getDayName(int dayOfWeek) {
    switch (dayOfWeek) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }

  String _getDayAbbr(int dayOfWeek) {
    switch (dayOfWeek) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '?';
    }
  }
}

// Helper class to group schedules
class _ScheduleGroup {
  final String? className;
  final String? teacherName;
  final String? startTime;
  final String? endTime;
  final List<int> days;

  _ScheduleGroup({
    this.className,
    this.teacherName,
    this.startTime,
    this.endTime,
    required this.days,
  });
}
