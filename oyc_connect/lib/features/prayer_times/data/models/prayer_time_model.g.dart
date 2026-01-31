// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prayer_time_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PrayerTimeImpl _$$PrayerTimeImplFromJson(Map<String, dynamic> json) =>
    _$PrayerTimeImpl(
      id: (json['id'] as num).toInt(),
      date: DateTime.parse(json['date'] as String),
      fajr: json['fajr'] as String,
      fajrIqama: json['fajr_iqama'] as String?,
      dhuhr: json['dhuhr'] as String,
      dhuhrIqama: json['dhuhr_iqama'] as String?,
      asr: json['asr'] as String,
      asrIqama: json['asr_iqama'] as String?,
      maghrib: json['maghrib'] as String,
      maghribIqama: json['maghrib_iqama'] as String?,
      isha: json['isha'] as String,
      ishaIqama: json['isha_iqama'] as String?,
      jumuah: json['jumuah'] as String?,
    );

Map<String, dynamic> _$$PrayerTimeImplToJson(_$PrayerTimeImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date.toIso8601String(),
      'fajr': instance.fajr,
      'fajr_iqama': instance.fajrIqama,
      'dhuhr': instance.dhuhr,
      'dhuhr_iqama': instance.dhuhrIqama,
      'asr': instance.asr,
      'asr_iqama': instance.asrIqama,
      'maghrib': instance.maghrib,
      'maghrib_iqama': instance.maghribIqama,
      'isha': instance.isha,
      'isha_iqama': instance.ishaIqama,
      'jumuah': instance.jumuah,
    };
