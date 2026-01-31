// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TeacherModelImpl _$$TeacherModelImplFromJson(Map<String, dynamic> json) =>
    _$TeacherModelImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      bio: json['bio'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$TeacherModelImplToJson(_$TeacherModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'bio': instance.bio,
      'created_at': instance.createdAt.toIso8601String(),
    };
