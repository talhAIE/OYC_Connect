import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/classes_providers.dart';
import '../../data/models/weekly_schedule_model.dart';

// Theme aligned with Community / Discover Hub
class _ClassesTheme {
  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color primaryTeal = Color(0xFF006D5B);
  static const Color quranAccent = Color(0xFF0F766E);
  static const Color labelGrey = Color(0xFF64748B);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color surfaceBg = Color(0xFFF8FAFC);
}

class ClassesSchedulePage extends ConsumerStatefulWidget {
  const ClassesSchedulePage({super.key});

  @override
  ConsumerState<ClassesSchedulePage> createState() =>
      _ClassesSchedulePageState();
}

class _ClassesSchedulePageState extends ConsumerState<ClassesSchedulePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();
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
    super.build(context);

    final weeklyAsync = ref.watch(weeklySchedulesProvider);
    final quranAsync = ref.watch(quranSchedulesProvider);

    return Scaffold(
      backgroundColor: _ClassesTheme.surfaceBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: _ClassesTheme.primaryTeal,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildInfoBanner(),
                const SizedBox(height: 28),
                _buildSectionLabel('WEEKLY SCHEDULE'),
                const SizedBox(height: 14),
                weeklyAsync.when(
                  data: (schedules) =>
                      _buildScheduleList(schedules, type: 'weekly'),
                  loading: () => _buildLoading(),
                  error: (err, stack) => _buildError('$err'),
                ),
                const SizedBox(height: 28),
                _buildSectionLabel("QUR'AN CLASSES"),
                const SizedBox(height: 14),
                quranAsync.when(
                  data: (schedules) =>
                      _buildScheduleList(schedules, type: 'quran'),
                  loading: () => _buildLoading(),
                  error: (err, stack) => _buildError('$err'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _ClassesTheme.primaryTeal.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.calendar_month_rounded,
            color: _ClassesTheme.primaryTeal,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Text(
            'Weekly Classes',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: _ClassesTheme.primaryNavy,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _ClassesTheme.primaryTeal.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _ClassesTheme.primaryTeal.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: _ClassesTheme.primaryTeal,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'All classes held between Maghrib & Isha, unless stated otherwise.',
              style: TextStyle(
                fontSize: 14,
                color: _ClassesTheme.primaryNavy.withOpacity(0.85),
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: _ClassesTheme.labelGrey,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            color: _ClassesTheme.primaryTeal,
            strokeWidth: 2.5,
          ),
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: Colors.red.shade700,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildScheduleList(
    List<WeeklyScheduleModel> schedules, {
    required String type,
  }) {
    if (schedules.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'No ${type == 'weekly' ? 'weekly' : "Qur'an"} classes scheduled yet.',
            style: TextStyle(
              color: _ClassesTheme.labelGrey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    final grouped = _groupSchedules(schedules);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: grouped.map((group) {
        return _buildScheduleCard(group, type: type);
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

  Widget _buildScheduleCard(
    _ScheduleGroup group, {
    required String type,
  }) {
    final isQuran = type == 'quran';
    final accentColor =
        isQuran ? _ClassesTheme.quranAccent : _ClassesTheme.primaryTeal;
    final iconBg = accentColor.withOpacity(0.12);
    final icon = isQuran
        ? Icons.auto_stories_rounded
        : Icons.event_note_rounded;
    final hasTime = group.startTime != null && group.endTime != null;
    final dayDisplay = _formatDayRange(group.days);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _ClassesTheme.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: _ClassesTheme.primaryNavy.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayDisplay,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  group.className ?? 'Unknown Class',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _ClassesTheme.primaryNavy,
                    letterSpacing: -0.3,
                  ),
                ),
                if (group.teacherName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    group.teacherName!,
                    style: TextStyle(
                      fontSize: 13,
                      color: _ClassesTheme.primaryNavy.withOpacity(0.65),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (hasTime)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: accentColor,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${group.startTime}–${group.endTime}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
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
