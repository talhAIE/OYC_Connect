import 'package:freezed_annotation/freezed_annotation.dart';

part 'prayer_time_model.freezed.dart';
part 'prayer_time_model.g.dart';

@freezed
class PrayerTime with _$PrayerTime {
  const factory PrayerTime({
    required int id,
    required DateTime date,
    required String fajr,
    @JsonKey(name: 'fajr_iqama') String? fajrIqama,
    required String dhuhr,
    @JsonKey(name: 'dhuhr_iqama') String? dhuhrIqama,
    required String asr,
    @JsonKey(name: 'asr_iqama') String? asrIqama,
    required String maghrib,
    @JsonKey(name: 'maghrib_iqama') String? maghribIqama,
    required String isha,
    @JsonKey(name: 'isha_iqama') String? ishaIqama,
    String? jumuah,
  }) = _PrayerTime;

  factory PrayerTime.fromJson(Map<String, dynamic> json) =>
      _$PrayerTimeFromJson(json);
}
