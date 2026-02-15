// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'announcement_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AnnouncementImpl _$$AnnouncementImplFromJson(Map<String, dynamic> json) =>
    _$AnnouncementImpl(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      content: json['body'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isUrgent: json['is_urgent'] as bool? ?? false,
      imageUrl: json['image_url'] as String?,
    );

Map<String, dynamic> _$$AnnouncementImplToJson(_$AnnouncementImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'body': instance.content,
      'created_at': instance.createdAt.toIso8601String(),
      'is_urgent': instance.isUrgent,
      'image_url': instance.imageUrl,
    };
