// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'prayer_time_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PrayerTime _$PrayerTimeFromJson(Map<String, dynamic> json) {
  return _PrayerTime.fromJson(json);
}

/// @nodoc
mixin _$PrayerTime {
  int get id => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  String get fajr => throw _privateConstructorUsedError;
  @JsonKey(name: 'fajr_iqama')
  String? get fajrIqama => throw _privateConstructorUsedError;
  String get dhuhr => throw _privateConstructorUsedError;
  @JsonKey(name: 'dhuhr_iqama')
  String? get dhuhrIqama => throw _privateConstructorUsedError;
  String get asr => throw _privateConstructorUsedError;
  @JsonKey(name: 'asr_iqama')
  String? get asrIqama => throw _privateConstructorUsedError;
  String get maghrib => throw _privateConstructorUsedError;
  @JsonKey(name: 'maghrib_iqama')
  String? get maghribIqama => throw _privateConstructorUsedError;
  String get isha => throw _privateConstructorUsedError;
  @JsonKey(name: 'isha_iqama')
  String? get ishaIqama => throw _privateConstructorUsedError;
  String? get jumuah => throw _privateConstructorUsedError;

  /// Serializes this PrayerTime to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PrayerTime
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PrayerTimeCopyWith<PrayerTime> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PrayerTimeCopyWith<$Res> {
  factory $PrayerTimeCopyWith(
    PrayerTime value,
    $Res Function(PrayerTime) then,
  ) = _$PrayerTimeCopyWithImpl<$Res, PrayerTime>;
  @useResult
  $Res call({
    int id,
    DateTime date,
    String fajr,
    @JsonKey(name: 'fajr_iqama') String? fajrIqama,
    String dhuhr,
    @JsonKey(name: 'dhuhr_iqama') String? dhuhrIqama,
    String asr,
    @JsonKey(name: 'asr_iqama') String? asrIqama,
    String maghrib,
    @JsonKey(name: 'maghrib_iqama') String? maghribIqama,
    String isha,
    @JsonKey(name: 'isha_iqama') String? ishaIqama,
    String? jumuah,
  });
}

/// @nodoc
class _$PrayerTimeCopyWithImpl<$Res, $Val extends PrayerTime>
    implements $PrayerTimeCopyWith<$Res> {
  _$PrayerTimeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PrayerTime
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? date = null,
    Object? fajr = null,
    Object? fajrIqama = freezed,
    Object? dhuhr = null,
    Object? dhuhrIqama = freezed,
    Object? asr = null,
    Object? asrIqama = freezed,
    Object? maghrib = null,
    Object? maghribIqama = freezed,
    Object? isha = null,
    Object? ishaIqama = freezed,
    Object? jumuah = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            fajr: null == fajr
                ? _value.fajr
                : fajr // ignore: cast_nullable_to_non_nullable
                      as String,
            fajrIqama: freezed == fajrIqama
                ? _value.fajrIqama
                : fajrIqama // ignore: cast_nullable_to_non_nullable
                      as String?,
            dhuhr: null == dhuhr
                ? _value.dhuhr
                : dhuhr // ignore: cast_nullable_to_non_nullable
                      as String,
            dhuhrIqama: freezed == dhuhrIqama
                ? _value.dhuhrIqama
                : dhuhrIqama // ignore: cast_nullable_to_non_nullable
                      as String?,
            asr: null == asr
                ? _value.asr
                : asr // ignore: cast_nullable_to_non_nullable
                      as String,
            asrIqama: freezed == asrIqama
                ? _value.asrIqama
                : asrIqama // ignore: cast_nullable_to_non_nullable
                      as String?,
            maghrib: null == maghrib
                ? _value.maghrib
                : maghrib // ignore: cast_nullable_to_non_nullable
                      as String,
            maghribIqama: freezed == maghribIqama
                ? _value.maghribIqama
                : maghribIqama // ignore: cast_nullable_to_non_nullable
                      as String?,
            isha: null == isha
                ? _value.isha
                : isha // ignore: cast_nullable_to_non_nullable
                      as String,
            ishaIqama: freezed == ishaIqama
                ? _value.ishaIqama
                : ishaIqama // ignore: cast_nullable_to_non_nullable
                      as String?,
            jumuah: freezed == jumuah
                ? _value.jumuah
                : jumuah // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PrayerTimeImplCopyWith<$Res>
    implements $PrayerTimeCopyWith<$Res> {
  factory _$$PrayerTimeImplCopyWith(
    _$PrayerTimeImpl value,
    $Res Function(_$PrayerTimeImpl) then,
  ) = __$$PrayerTimeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    DateTime date,
    String fajr,
    @JsonKey(name: 'fajr_iqama') String? fajrIqama,
    String dhuhr,
    @JsonKey(name: 'dhuhr_iqama') String? dhuhrIqama,
    String asr,
    @JsonKey(name: 'asr_iqama') String? asrIqama,
    String maghrib,
    @JsonKey(name: 'maghrib_iqama') String? maghribIqama,
    String isha,
    @JsonKey(name: 'isha_iqama') String? ishaIqama,
    String? jumuah,
  });
}

/// @nodoc
class __$$PrayerTimeImplCopyWithImpl<$Res>
    extends _$PrayerTimeCopyWithImpl<$Res, _$PrayerTimeImpl>
    implements _$$PrayerTimeImplCopyWith<$Res> {
  __$$PrayerTimeImplCopyWithImpl(
    _$PrayerTimeImpl _value,
    $Res Function(_$PrayerTimeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PrayerTime
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? date = null,
    Object? fajr = null,
    Object? fajrIqama = freezed,
    Object? dhuhr = null,
    Object? dhuhrIqama = freezed,
    Object? asr = null,
    Object? asrIqama = freezed,
    Object? maghrib = null,
    Object? maghribIqama = freezed,
    Object? isha = null,
    Object? ishaIqama = freezed,
    Object? jumuah = freezed,
  }) {
    return _then(
      _$PrayerTimeImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        fajr: null == fajr
            ? _value.fajr
            : fajr // ignore: cast_nullable_to_non_nullable
                  as String,
        fajrIqama: freezed == fajrIqama
            ? _value.fajrIqama
            : fajrIqama // ignore: cast_nullable_to_non_nullable
                  as String?,
        dhuhr: null == dhuhr
            ? _value.dhuhr
            : dhuhr // ignore: cast_nullable_to_non_nullable
                  as String,
        dhuhrIqama: freezed == dhuhrIqama
            ? _value.dhuhrIqama
            : dhuhrIqama // ignore: cast_nullable_to_non_nullable
                  as String?,
        asr: null == asr
            ? _value.asr
            : asr // ignore: cast_nullable_to_non_nullable
                  as String,
        asrIqama: freezed == asrIqama
            ? _value.asrIqama
            : asrIqama // ignore: cast_nullable_to_non_nullable
                  as String?,
        maghrib: null == maghrib
            ? _value.maghrib
            : maghrib // ignore: cast_nullable_to_non_nullable
                  as String,
        maghribIqama: freezed == maghribIqama
            ? _value.maghribIqama
            : maghribIqama // ignore: cast_nullable_to_non_nullable
                  as String?,
        isha: null == isha
            ? _value.isha
            : isha // ignore: cast_nullable_to_non_nullable
                  as String,
        ishaIqama: freezed == ishaIqama
            ? _value.ishaIqama
            : ishaIqama // ignore: cast_nullable_to_non_nullable
                  as String?,
        jumuah: freezed == jumuah
            ? _value.jumuah
            : jumuah // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PrayerTimeImpl implements _PrayerTime {
  const _$PrayerTimeImpl({
    required this.id,
    required this.date,
    required this.fajr,
    @JsonKey(name: 'fajr_iqama') this.fajrIqama,
    required this.dhuhr,
    @JsonKey(name: 'dhuhr_iqama') this.dhuhrIqama,
    required this.asr,
    @JsonKey(name: 'asr_iqama') this.asrIqama,
    required this.maghrib,
    @JsonKey(name: 'maghrib_iqama') this.maghribIqama,
    required this.isha,
    @JsonKey(name: 'isha_iqama') this.ishaIqama,
    this.jumuah,
  });

  factory _$PrayerTimeImpl.fromJson(Map<String, dynamic> json) =>
      _$$PrayerTimeImplFromJson(json);

  @override
  final int id;
  @override
  final DateTime date;
  @override
  final String fajr;
  @override
  @JsonKey(name: 'fajr_iqama')
  final String? fajrIqama;
  @override
  final String dhuhr;
  @override
  @JsonKey(name: 'dhuhr_iqama')
  final String? dhuhrIqama;
  @override
  final String asr;
  @override
  @JsonKey(name: 'asr_iqama')
  final String? asrIqama;
  @override
  final String maghrib;
  @override
  @JsonKey(name: 'maghrib_iqama')
  final String? maghribIqama;
  @override
  final String isha;
  @override
  @JsonKey(name: 'isha_iqama')
  final String? ishaIqama;
  @override
  final String? jumuah;

  @override
  String toString() {
    return 'PrayerTime(id: $id, date: $date, fajr: $fajr, fajrIqama: $fajrIqama, dhuhr: $dhuhr, dhuhrIqama: $dhuhrIqama, asr: $asr, asrIqama: $asrIqama, maghrib: $maghrib, maghribIqama: $maghribIqama, isha: $isha, ishaIqama: $ishaIqama, jumuah: $jumuah)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PrayerTimeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.fajr, fajr) || other.fajr == fajr) &&
            (identical(other.fajrIqama, fajrIqama) ||
                other.fajrIqama == fajrIqama) &&
            (identical(other.dhuhr, dhuhr) || other.dhuhr == dhuhr) &&
            (identical(other.dhuhrIqama, dhuhrIqama) ||
                other.dhuhrIqama == dhuhrIqama) &&
            (identical(other.asr, asr) || other.asr == asr) &&
            (identical(other.asrIqama, asrIqama) ||
                other.asrIqama == asrIqama) &&
            (identical(other.maghrib, maghrib) || other.maghrib == maghrib) &&
            (identical(other.maghribIqama, maghribIqama) ||
                other.maghribIqama == maghribIqama) &&
            (identical(other.isha, isha) || other.isha == isha) &&
            (identical(other.ishaIqama, ishaIqama) ||
                other.ishaIqama == ishaIqama) &&
            (identical(other.jumuah, jumuah) || other.jumuah == jumuah));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    date,
    fajr,
    fajrIqama,
    dhuhr,
    dhuhrIqama,
    asr,
    asrIqama,
    maghrib,
    maghribIqama,
    isha,
    ishaIqama,
    jumuah,
  );

  /// Create a copy of PrayerTime
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PrayerTimeImplCopyWith<_$PrayerTimeImpl> get copyWith =>
      __$$PrayerTimeImplCopyWithImpl<_$PrayerTimeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PrayerTimeImplToJson(this);
  }
}

abstract class _PrayerTime implements PrayerTime {
  const factory _PrayerTime({
    required final int id,
    required final DateTime date,
    required final String fajr,
    @JsonKey(name: 'fajr_iqama') final String? fajrIqama,
    required final String dhuhr,
    @JsonKey(name: 'dhuhr_iqama') final String? dhuhrIqama,
    required final String asr,
    @JsonKey(name: 'asr_iqama') final String? asrIqama,
    required final String maghrib,
    @JsonKey(name: 'maghrib_iqama') final String? maghribIqama,
    required final String isha,
    @JsonKey(name: 'isha_iqama') final String? ishaIqama,
    final String? jumuah,
  }) = _$PrayerTimeImpl;

  factory _PrayerTime.fromJson(Map<String, dynamic> json) =
      _$PrayerTimeImpl.fromJson;

  @override
  int get id;
  @override
  DateTime get date;
  @override
  String get fajr;
  @override
  @JsonKey(name: 'fajr_iqama')
  String? get fajrIqama;
  @override
  String get dhuhr;
  @override
  @JsonKey(name: 'dhuhr_iqama')
  String? get dhuhrIqama;
  @override
  String get asr;
  @override
  @JsonKey(name: 'asr_iqama')
  String? get asrIqama;
  @override
  String get maghrib;
  @override
  @JsonKey(name: 'maghrib_iqama')
  String? get maghribIqama;
  @override
  String get isha;
  @override
  @JsonKey(name: 'isha_iqama')
  String? get ishaIqama;
  @override
  String? get jumuah;

  /// Create a copy of PrayerTime
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PrayerTimeImplCopyWith<_$PrayerTimeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
