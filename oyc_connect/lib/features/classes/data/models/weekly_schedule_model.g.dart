// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weekly_schedule_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WeeklyScheduleModelImpl _$$WeeklyScheduleModelImplFromJson(
  Map<String, dynamic> json,
) => _$WeeklyScheduleModelImpl(
  id: (json['id'] as num).toInt(),
  dayOfWeek: (json['day_of_week'] as num).toInt(),
  classId: (json['class_id'] as num).toInt(),
  className: json['class_name'] as String?,
  teacherId: (json['teacher_id'] as num?)?.toInt(),
  teacherName: json['teacher_name'] as String?,
  startTime: json['start_time'] as String?,
  endTime: json['end_time'] as String?,
  scheduleType: json['schedule_type'] as String? ?? 'weekly',
  notes: json['notes'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$$WeeklyScheduleModelImplToJson(
  _$WeeklyScheduleModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'day_of_week': instance.dayOfWeek,
  'class_id': instance.classId,
  'class_name': instance.className,
  'teacher_id': instance.teacherId,
  'teacher_name': instance.teacherName,
  'start_time': instance.startTime,
  'end_time': instance.endTime,
  'schedule_type': instance.scheduleType,
  'notes': instance.notes,
  'created_at': instance.createdAt.toIso8601String(),
};
