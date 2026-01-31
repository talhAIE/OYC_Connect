import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/schedule_repository.dart';
import '../providers/classes_providers.dart';

class ManageSchedulePage extends ConsumerStatefulWidget {
  const ManageSchedulePage({super.key});

  @override
  ConsumerState<ManageSchedulePage> createState() => _ManageSchedulePageState();
}

class _ManageSchedulePageState extends ConsumerState<ManageSchedulePage> {
  @override
  Widget build(BuildContext context) {
    final allSchedulesAsync = ref.watch(allSchedulesProvider);
    final classesAsync = ref.watch(allClassesProvider);
    final teachersAsync = ref.watch(allTeachersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Manage Schedule',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Header section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                // Add New Schedule Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (classesAsync.hasValue && teachersAsync.hasValue) {
                        _showAddScheduleDialog(
                          classesAsync.value!,
                          teachersAsync.value!,
                        );
                      }
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(
                      'Add New Schedule',
                      style: TextStyle(fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Quick Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/profile/admin/classes'),
                        icon: const Icon(Icons.library_books, size: 14),
                        label: const Text(
                          'Manage Classes',
                          style: TextStyle(fontSize: 11),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: const BorderSide(color: Color(0xFF1B5E20)),
                          foregroundColor: const Color(0xFF1B5E20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            context.push('/profile/admin/teachers'),
                        icon: const Icon(Icons.person, size: 14),
                        label: const Text(
                          'Manage Teachers',
                          style: TextStyle(fontSize: 11),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: const BorderSide(color: Color(0xFF1B5E20)),
                          foregroundColor: const Color(0xFF1B5E20),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Scrollable content
          Expanded(
            child: allSchedulesAsync.when(
              data: (allSchedules) {
                if (allSchedules.isEmpty) {
                  return const Center(
                    child: Text(
                      'No schedules yet.\nTap "Add New Schedule" to begin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  );
                }

                // Separate weekly and quran
                final weeklySchedules = allSchedules
                    .where((s) => s.scheduleType == 'weekly')
                    .toList();
                final quranSchedules = allSchedules
                    .where((s) => s.scheduleType == 'quran')
                    .toList();

                // Sort both by day
                weeklySchedules.sort(
                  (a, b) => a.dayOfWeek.compareTo(b.dayOfWeek),
                );
                quranSchedules.sort(
                  (a, b) => a.dayOfWeek.compareTo(b.dayOfWeek),
                );

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    80,
                  ), // Add bottom padding for nav bar
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Weekly Classes Section
                      if (weeklySchedules.isNotEmpty) ...[
                        const Text(
                          'WEEKLY CLASSES',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...weeklySchedules.map((schedule) {
                          return _buildScheduleCard(
                            schedule,
                            classesAsync.value,
                            teachersAsync.value,
                            const Color(0xFF1B5E20),
                            const Color(0xFFE8F5E9),
                          );
                        }),
                        const SizedBox(height: 20),
                      ],

                      // Qur'an Classes Section
                      if (quranSchedules.isNotEmpty) ...[
                        const Text(
                          'QUR\'AN CLASSES',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...quranSchedules.map((schedule) {
                          return _buildScheduleCard(
                            schedule,
                            classesAsync.value,
                            teachersAsync.value,
                            const Color(0xFF6A1B9A),
                            const Color(0xFFF3E5F5),
                          );
                        }),
                      ],
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(
    schedule,
    classes,
    teachers,
    Color color,
    Color bgColor,
  ) {
    final dayName = _getDayName(schedule.dayOfWeek);
    final hasTime = schedule.startTime != null && schedule.endTime != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Day badge
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  dayName.substring(0, 3).toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  dayName.substring(3).toLowerCase(),
                  style: TextStyle(fontSize: 9, color: color.withOpacity(0.7)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.className ?? 'Unknown Class',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (schedule.teacherName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'By ${schedule.teacherName}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
                if (hasTime) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: color),
                      const SizedBox(width: 4),
                      Text(
                        '${schedule.startTime} - ${schedule.endTime}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Actions
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () {
                  if (classes != null && teachers != null) {
                    _showEditScheduleDialog(schedule, classes, teachers);
                  }
                },
                color: Colors.blue,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(height: 4),
              IconButton(
                icon: const Icon(Icons.delete, size: 18),
                onPressed: () => _confirmDelete(schedule.id),
                color: Colors.red,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddScheduleDialog(classes, teachers) {
    showDialog(
      context: context,
      builder: (context) => _ScheduleDialog(
        classes: classes,
        teachers: teachers,
        onSave:
            (
              selectedDays,
              classId,
              teacherId,
              startTime,
              endTime,
              scheduleType,
            ) async {
              try {
                final repository = ref.read(scheduleRepositoryProvider);

                for (int day in selectedDays) {
                  await repository.addSchedule(
                    dayOfWeek: day,
                    classId: classId,
                    teacherId: teacherId,
                    startTime: startTime,
                    endTime: endTime,
                    scheduleType: scheduleType,
                  );
                }

                ref.invalidate(allSchedulesProvider);
                ref.invalidate(weeklySchedulesProvider);
                ref.invalidate(quranSchedulesProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Schedule added for ${selectedDays.length} day(s)!',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
      ),
    );
  }

  void _showEditScheduleDialog(schedule, classes, teachers) {
    showDialog(
      context: context,
      builder: (context) => _ScheduleDialog(
        schedule: schedule,
        classes: classes,
        teachers: teachers,
        onSave:
            (
              selectedDays,
              classId,
              teacherId,
              startTime,
              endTime,
              scheduleType,
            ) async {
              try {
                final repository = ref.read(scheduleRepositoryProvider);
                await repository.updateSchedule(
                  id: schedule.id,
                  dayOfWeek: selectedDays.first,
                  classId: classId,
                  teacherId: teacherId,
                  startTime: startTime,
                  endTime: endTime,
                  scheduleType: scheduleType,
                );
                ref.invalidate(allSchedulesProvider);
                ref.invalidate(weeklySchedulesProvider);
                ref.invalidate(quranSchedulesProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Schedule updated successfully!'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
      ),
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: const Text(
          'Are you sure you want to delete this schedule entry?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final repository = ref.read(scheduleRepositoryProvider);
                await repository.deleteSchedule(id);
                ref.invalidate(allSchedulesProvider);
                ref.invalidate(weeklySchedulesProvider);
                ref.invalidate(quranSchedulesProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Schedule deleted successfully!'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
}

// Dialog for Add/Edit Schedule
class _ScheduleDialog extends StatefulWidget {
  final dynamic schedule;
  final List classes;
  final List teachers;
  final Function(List<int>, int, int?, String?, String?, String) onSave;

  const _ScheduleDialog({
    this.schedule,
    required this.classes,
    required this.teachers,
    required this.onSave,
  });

  @override
  State<_ScheduleDialog> createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends State<_ScheduleDialog> {
  final Set<int> _selectedDays = {};
  late int? _selectedClass;
  late int? _selectedTeacher;
  late String _scheduleType;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    if (widget.schedule != null) {
      _selectedDays.add(widget.schedule.dayOfWeek);
    }
    _selectedClass = widget.schedule?.classId;
    _selectedTeacher = widget.schedule?.teacherId;
    _scheduleType = widget.schedule?.scheduleType ?? 'weekly';

    if (widget.schedule?.startTime != null) {
      _startTime = _parseTime(widget.schedule.startTime);
    }
    if (widget.schedule?.endTime != null) {
      _endTime = _parseTime(widget.schedule.endTime);
    }
  }

  TimeOfDay? _parseTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    try {
      final parts = timeStr.replaceAll(RegExp(r'[^0-9:]'), '').split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1].split(' ')[0]);

        if (timeStr.toUpperCase().contains('PM') && hour != 12) {
          hour += 12;
        } else if (timeStr.toUpperCase().contains('AM') && hour == 12) {
          hour = 0;
        }

        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {}
    return null;
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _pickTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: (isStartTime ? _startTime : _endTime) ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.schedule == null ? 'Add Schedule' : 'Edit Schedule'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Days:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (index) {
                final day = index + 1;
                final isSelected = _selectedDays.contains(day);
                return FilterChip(
                  label: Text(_getDayAbbr(day)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedDays.add(day);
                      } else {
                        _selectedDays.remove(day);
                      }
                    });
                  },
                  selectedColor: const Color(0xFF1B5E20),
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            const Text('Class:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _selectedClass,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: widget.classes
                  .map<DropdownMenuItem<int>>(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedClass = value),
            ),
            const SizedBox(height: 16),
            const Text(
              'Teacher:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _selectedTeacher,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: widget.teachers
                  .map<DropdownMenuItem<int>>(
                    (t) => DropdownMenuItem(value: t.id, child: Text(t.name)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedTeacher = value),
            ),
            const SizedBox(height: 16),
            const Text('Type:', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Weekly'),
                    value: 'weekly',
                    groupValue: _scheduleType,
                    onChanged: (value) =>
                        setState(() => _scheduleType = value!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text("Qur'an"),
                    value: 'quran',
                    groupValue: _scheduleType,
                    onChanged: (value) =>
                        setState(() => _scheduleType = value!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Time (Optional):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(true),
                    icon: const Icon(Icons.access_time, size: 16),
                    label: Text(
                      _startTime != null
                          ? _formatTimeOfDay(_startTime!)
                          : 'Start',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(false),
                    icon: const Icon(Icons.access_time, size: 16),
                    label: Text(
                      _endTime != null ? _formatTimeOfDay(_endTime!) : 'End',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
            if (_startTime != null || _endTime != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() {
                    _startTime = null;
                    _endTime = null;
                  }),
                  child: const Text('Clear'),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_selectedDays.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select at least one day')),
              );
              return;
            }
            if (_selectedClass == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select a class')),
              );
              return;
            }

            widget.onSave(
              _selectedDays.toList()..sort(),
              _selectedClass!,
              _selectedTeacher,
              _startTime != null ? _formatTimeOfDay(_startTime!) : null,
              _endTime != null ? _formatTimeOfDay(_endTime!) : null,
              _scheduleType,
            );
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B5E20),
          ),
          child: const Text('Save'),
        ),
      ],
    );
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
