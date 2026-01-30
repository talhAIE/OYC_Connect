import 'package:freezed_annotation/freezed_annotation.dart';

part 'weekly_schedule_model.freezed.dart';
part 'weekly_schedule_model.g.dart';

@freezed
class WeeklyScheduleModel with _$WeeklyScheduleModel {
  const factory WeeklyScheduleModel({
    required int id,
    @JsonKey(name: 'day_of_week') required int dayOfWeek,
    @JsonKey(name: 'class_id') required int classId,
    @JsonKey(name: 'class_name') String? className, // Joined from classes table
    @JsonKey(name: 'teacher_id') int? teacherId,
    @JsonKey(name: 'teacher_name')
    String? teacherName, // Joined from teachers table
    @JsonKey(name: 'start_time') String? startTime,
    @JsonKey(name: 'end_time') String? endTime,
    @JsonKey(name: 'schedule_type') @Default('weekly') String scheduleType,
    String? notes,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _WeeklyScheduleModel;

  factory WeeklyScheduleModel.fromJson(Map<String, dynamic> json) =>
      _$WeeklyScheduleModelFromJson(json);
}
