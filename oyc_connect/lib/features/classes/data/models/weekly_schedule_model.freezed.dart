// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'weekly_schedule_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

WeeklyScheduleModel _$WeeklyScheduleModelFromJson(Map<String, dynamic> json) {
  return _WeeklyScheduleModel.fromJson(json);
}

/// @nodoc
mixin _$WeeklyScheduleModel {
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'day_of_week')
  int get dayOfWeek => throw _privateConstructorUsedError;
  @JsonKey(name: 'class_id')
  int get classId => throw _privateConstructorUsedError;
  @JsonKey(name: 'class_name')
  String? get className => throw _privateConstructorUsedError; // Joined from classes table
  @JsonKey(name: 'teacher_id')
  int? get teacherId => throw _privateConstructorUsedError;
  @JsonKey(name: 'teacher_name')
  String? get teacherName => throw _privateConstructorUsedError; // Joined from teachers table
  @JsonKey(name: 'start_time')
  String? get startTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'end_time')
  String? get endTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'schedule_type')
  String get scheduleType => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this WeeklyScheduleModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WeeklyScheduleModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WeeklyScheduleModelCopyWith<WeeklyScheduleModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WeeklyScheduleModelCopyWith<$Res> {
  factory $WeeklyScheduleModelCopyWith(
    WeeklyScheduleModel value,
    $Res Function(WeeklyScheduleModel) then,
  ) = _$WeeklyScheduleModelCopyWithImpl<$Res, WeeklyScheduleModel>;
  @useResult
  $Res call({
    int id,
    @JsonKey(name: 'day_of_week') int dayOfWeek,
    @JsonKey(name: 'class_id') int classId,
    @JsonKey(name: 'class_name') String? className,
    @JsonKey(name: 'teacher_id') int? teacherId,
    @JsonKey(name: 'teacher_name') String? teacherName,
    @JsonKey(name: 'start_time') String? startTime,
    @JsonKey(name: 'end_time') String? endTime,
    @JsonKey(name: 'schedule_type') String scheduleType,
    String? notes,
    @JsonKey(name: 'created_at') DateTime createdAt,
  });
}

/// @nodoc
class _$WeeklyScheduleModelCopyWithImpl<$Res, $Val extends WeeklyScheduleModel>
    implements $WeeklyScheduleModelCopyWith<$Res> {
  _$WeeklyScheduleModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WeeklyScheduleModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? dayOfWeek = null,
    Object? classId = null,
    Object? className = freezed,
    Object? teacherId = freezed,
    Object? teacherName = freezed,
    Object? startTime = freezed,
    Object? endTime = freezed,
    Object? scheduleType = null,
    Object? notes = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            dayOfWeek: null == dayOfWeek
                ? _value.dayOfWeek
                : dayOfWeek // ignore: cast_nullable_to_non_nullable
                      as int,
            classId: null == classId
                ? _value.classId
                : classId // ignore: cast_nullable_to_non_nullable
                      as int,
            className: freezed == className
                ? _value.className
                : className // ignore: cast_nullable_to_non_nullable
                      as String?,
            teacherId: freezed == teacherId
                ? _value.teacherId
                : teacherId // ignore: cast_nullable_to_non_nullable
                      as int?,
            teacherName: freezed == teacherName
                ? _value.teacherName
                : teacherName // ignore: cast_nullable_to_non_nullable
                      as String?,
            startTime: freezed == startTime
                ? _value.startTime
                : startTime // ignore: cast_nullable_to_non_nullable
                      as String?,
            endTime: freezed == endTime
                ? _value.endTime
                : endTime // ignore: cast_nullable_to_non_nullable
                      as String?,
            scheduleType: null == scheduleType
                ? _value.scheduleType
                : scheduleType // ignore: cast_nullable_to_non_nullable
                      as String,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$WeeklyScheduleModelImplCopyWith<$Res>
    implements $WeeklyScheduleModelCopyWith<$Res> {
  factory _$$WeeklyScheduleModelImplCopyWith(
    _$WeeklyScheduleModelImpl value,
    $Res Function(_$WeeklyScheduleModelImpl) then,
  ) = __$$WeeklyScheduleModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    @JsonKey(name: 'day_of_week') int dayOfWeek,
    @JsonKey(name: 'class_id') int classId,
    @JsonKey(name: 'class_name') String? className,
    @JsonKey(name: 'teacher_id') int? teacherId,
    @JsonKey(name: 'teacher_name') String? teacherName,
    @JsonKey(name: 'start_time') String? startTime,
    @JsonKey(name: 'end_time') String? endTime,
    @JsonKey(name: 'schedule_type') String scheduleType,
    String? notes,
    @JsonKey(name: 'created_at') DateTime createdAt,
  });
}

/// @nodoc
class __$$WeeklyScheduleModelImplCopyWithImpl<$Res>
    extends _$WeeklyScheduleModelCopyWithImpl<$Res, _$WeeklyScheduleModelImpl>
    implements _$$WeeklyScheduleModelImplCopyWith<$Res> {
  __$$WeeklyScheduleModelImplCopyWithImpl(
    _$WeeklyScheduleModelImpl _value,
    $Res Function(_$WeeklyScheduleModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WeeklyScheduleModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? dayOfWeek = null,
    Object? classId = null,
    Object? className = freezed,
    Object? teacherId = freezed,
    Object? teacherName = freezed,
    Object? startTime = freezed,
    Object? endTime = freezed,
    Object? scheduleType = null,
    Object? notes = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _$WeeklyScheduleModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        dayOfWeek: null == dayOfWeek
            ? _value.dayOfWeek
            : dayOfWeek // ignore: cast_nullable_to_non_nullable
                  as int,
        classId: null == classId
            ? _value.classId
            : classId // ignore: cast_nullable_to_non_nullable
                  as int,
        className: freezed == className
            ? _value.className
            : className // ignore: cast_nullable_to_non_nullable
                  as String?,
        teacherId: freezed == teacherId
            ? _value.teacherId
            : teacherId // ignore: cast_nullable_to_non_nullable
                  as int?,
        teacherName: freezed == teacherName
            ? _value.teacherName
            : teacherName // ignore: cast_nullable_to_non_nullable
                  as String?,
        startTime: freezed == startTime
            ? _value.startTime
            : startTime // ignore: cast_nullable_to_non_nullable
                  as String?,
        endTime: freezed == endTime
            ? _value.endTime
            : endTime // ignore: cast_nullable_to_non_nullable
                  as String?,
        scheduleType: null == scheduleType
            ? _value.scheduleType
            : scheduleType // ignore: cast_nullable_to_non_nullable
                  as String,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$WeeklyScheduleModelImpl implements _WeeklyScheduleModel {
  const _$WeeklyScheduleModelImpl({
    required this.id,
    @JsonKey(name: 'day_of_week') required this.dayOfWeek,
    @JsonKey(name: 'class_id') required this.classId,
    @JsonKey(name: 'class_name') this.className,
    @JsonKey(name: 'teacher_id') this.teacherId,
    @JsonKey(name: 'teacher_name') this.teacherName,
    @JsonKey(name: 'start_time') this.startTime,
    @JsonKey(name: 'end_time') this.endTime,
    @JsonKey(name: 'schedule_type') this.scheduleType = 'weekly',
    this.notes,
    @JsonKey(name: 'created_at') required this.createdAt,
  });

  factory _$WeeklyScheduleModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$WeeklyScheduleModelImplFromJson(json);

  @override
  final int id;
  @override
  @JsonKey(name: 'day_of_week')
  final int dayOfWeek;
  @override
  @JsonKey(name: 'class_id')
  final int classId;
  @override
  @JsonKey(name: 'class_name')
  final String? className;
  // Joined from classes table
  @override
  @JsonKey(name: 'teacher_id')
  final int? teacherId;
  @override
  @JsonKey(name: 'teacher_name')
  final String? teacherName;
  // Joined from teachers table
  @override
  @JsonKey(name: 'start_time')
  final String? startTime;
  @override
  @JsonKey(name: 'end_time')
  final String? endTime;
  @override
  @JsonKey(name: 'schedule_type')
  final String scheduleType;
  @override
  final String? notes;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @override
  String toString() {
    return 'WeeklyScheduleModel(id: $id, dayOfWeek: $dayOfWeek, classId: $classId, className: $className, teacherId: $teacherId, teacherName: $teacherName, startTime: $startTime, endTime: $endTime, scheduleType: $scheduleType, notes: $notes, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WeeklyScheduleModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.dayOfWeek, dayOfWeek) ||
                other.dayOfWeek == dayOfWeek) &&
            (identical(other.classId, classId) || other.classId == classId) &&
            (identical(other.className, className) ||
                other.className == className) &&
            (identical(other.teacherId, teacherId) ||
                other.teacherId == teacherId) &&
            (identical(other.teacherName, teacherName) ||
                other.teacherName == teacherName) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.scheduleType, scheduleType) ||
                other.scheduleType == scheduleType) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    dayOfWeek,
    classId,
    className,
    teacherId,
    teacherName,
    startTime,
    endTime,
    scheduleType,
    notes,
    createdAt,
  );

  /// Create a copy of WeeklyScheduleModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WeeklyScheduleModelImplCopyWith<_$WeeklyScheduleModelImpl> get copyWith =>
      __$$WeeklyScheduleModelImplCopyWithImpl<_$WeeklyScheduleModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$WeeklyScheduleModelImplToJson(this);
  }
}

abstract class _WeeklyScheduleModel implements WeeklyScheduleModel {
  const factory _WeeklyScheduleModel({
    required final int id,
    @JsonKey(name: 'day_of_week') required final int dayOfWeek,
    @JsonKey(name: 'class_id') required final int classId,
    @JsonKey(name: 'class_name') final String? className,
    @JsonKey(name: 'teacher_id') final int? teacherId,
    @JsonKey(name: 'teacher_name') final String? teacherName,
    @JsonKey(name: 'start_time') final String? startTime,
    @JsonKey(name: 'end_time') final String? endTime,
    @JsonKey(name: 'schedule_type') final String scheduleType,
    final String? notes,
    @JsonKey(name: 'created_at') required final DateTime createdAt,
  }) = _$WeeklyScheduleModelImpl;

  factory _WeeklyScheduleModel.fromJson(Map<String, dynamic> json) =
      _$WeeklyScheduleModelImpl.fromJson;

  @override
  int get id;
  @override
  @JsonKey(name: 'day_of_week')
  int get dayOfWeek;
  @override
  @JsonKey(name: 'class_id')
  int get classId;
  @override
  @JsonKey(name: 'class_name')
  String? get className; // Joined from classes table
  @override
  @JsonKey(name: 'teacher_id')
  int? get teacherId;
  @override
  @JsonKey(name: 'teacher_name')
  String? get teacherName; // Joined from teachers table
  @override
  @JsonKey(name: 'start_time')
  String? get startTime;
  @override
  @JsonKey(name: 'end_time')
  String? get endTime;
  @override
  @JsonKey(name: 'schedule_type')
  String get scheduleType;
  @override
  String? get notes;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Create a copy of WeeklyScheduleModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WeeklyScheduleModelImplCopyWith<_$WeeklyScheduleModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
