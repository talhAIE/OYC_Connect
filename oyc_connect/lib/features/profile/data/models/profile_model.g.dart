// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProfileModelImpl _$$ProfileModelImplFromJson(Map<String, dynamic> json) =>
    _$ProfileModelImpl(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'member',
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
    );

Map<String, dynamic> _$$ProfileModelImplToJson(_$ProfileModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'full_name': instance.fullName,
      'email': instance.email,
      'role': instance.role,
      'notifications_enabled': instance.notificationsEnabled,
    };
