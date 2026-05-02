// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EventImpl _$$EventImplFromJson(Map<String, dynamic> json) => _$EventImpl(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  description: json['description'] as String?,
  eventDate: DateTime.parse(json['event_date'] as String),
  location: json['location'] as String?,
  imageUrl: json['image_url'] as String?,
  isFeatured: json['is_featured'] as bool? ?? false,
);

Map<String, dynamic> _$$EventImplToJson(_$EventImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'event_date': instance.eventDate.toIso8601String(),
      'location': instance.location,
      'image_url': instance.imageUrl,
      'is_featured': instance.isFeatured,
    };
