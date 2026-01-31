// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jummah_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$JummahConfigImpl _$$JummahConfigImplFromJson(Map<String, dynamic> json) =>
    _$JummahConfigImpl(
      id: json['id'] as String,
      khutbahTime: json['khutbah_time'] as String,
      jummahTime: json['jummah_time'] as String,
      address: json['address'] as String,
    );

Map<String, dynamic> _$$JummahConfigImplToJson(_$JummahConfigImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'khutbah_time': instance.khutbahTime,
      'jummah_time': instance.jummahTime,
      'address': instance.address,
    };
