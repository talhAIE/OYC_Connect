import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/weekly_schedule_model.dart';

part 'schedule_repository.g.dart';

class ScheduleRepository {
  final SupabaseClient _supabase;

  ScheduleRepository(this._supabase);

  // Fetch all schedules with JOIN to get class and teacher names
  Future<List<WeeklyScheduleModel>> getAllSchedules() async {
    final response = await _supabase
        .from('weekly_schedules')
        .select('''
          *,
          classes!weekly_schedules_class_id_fkey(name),
          teachers!weekly_schedules_teacher_id_fkey(name)
        ''')
        .order('day_of_week', ascending: true);

    return (response as List).map((json) {
      // Flatten the nested structure
      final flatJson = Map<String, dynamic>.from(json);
      if (json['classes'] != null) {
        flatJson['class_name'] = json['classes']['name'];
      }
      if (json['teachers'] != null) {
        flatJson['teacher_name'] = json['teachers']['name'];
      }
      flatJson.remove('classes');
      flatJson.remove('teachers');

      return WeeklyScheduleModel.fromJson(flatJson);
    }).toList();
  }

  // Get schedules by type (weekly or quran)
  Future<List<WeeklyScheduleModel>> getSchedulesByType(String type) async {
    final response = await _supabase
        .from('weekly_schedules')
        .select('''
          *,
          classes!weekly_schedules_class_id_fkey(name),
          teachers!weekly_schedules_teacher_id_fkey(name)
        ''')
        .eq('schedule_type', type)
        .order('day_of_week', ascending: true);

    return (response as List).map((json) {
      final flatJson = Map<String, dynamic>.from(json);
      if (json['classes'] != null) {
        flatJson['class_name'] = json['classes']['name'];
      }
      if (json['teachers'] != null) {
        flatJson['teacher_name'] = json['teachers']['name'];
      }
      flatJson.remove('classes');
      flatJson.remove('teachers');

      return WeeklyScheduleModel.fromJson(flatJson);
    }).toList();
  }

  // Add new schedule
  Future<void> addSchedule({
    required int dayOfWeek,
    required int classId,
    int? teacherId,
    String? startTime,
    String? endTime,
    String scheduleType = 'weekly',
    String? notes,
  }) async {
    await _supabase.from('weekly_schedules').insert({
      'day_of_week': dayOfWeek,
      'class_id': classId,
      'teacher_id': teacherId,
      'start_time': startTime,
      'end_time': endTime,
      'schedule_type': scheduleType,
      'notes': notes,
    });
  }

  // Delete schedule
  Future<void> deleteSchedule(int id) async {
    await _supabase.from('weekly_schedules').delete().eq('id', id);
  }

  // Update schedule
  Future<void> updateSchedule({
    required int id,
    int? dayOfWeek,
    int? classId,
    int? teacherId,
    String? startTime,
    String? endTime,
    String? scheduleType,
    String? notes,
  }) async {
    final Map<String, dynamic> updates = {};
    if (dayOfWeek != null) updates['day_of_week'] = dayOfWeek;
    if (classId != null) updates['class_id'] = classId;
    if (teacherId != null) updates['teacher_id'] = teacherId;
    if (startTime != null) updates['start_time'] = startTime;
    if (endTime != null) updates['end_time'] = endTime;
    if (scheduleType != null) updates['schedule_type'] = scheduleType;
    if (notes != null) updates['notes'] = notes;

    await _supabase.from('weekly_schedules').update(updates).eq('id', id);
  }
}

@riverpod
ScheduleRepository scheduleRepository(ScheduleRepositoryRef ref) {
  return ScheduleRepository(Supabase.instance.client);
}
