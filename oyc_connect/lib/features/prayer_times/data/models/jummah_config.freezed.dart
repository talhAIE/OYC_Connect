// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'jummah_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

JummahConfig _$JummahConfigFromJson(Map<String, dynamic> json) {
  return _JummahConfig.fromJson(json);
}

/// @nodoc
mixin _$JummahConfig {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'khutbah_time')
  String get khutbahTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'jummah_time')
  String get jummahTime => throw _privateConstructorUsedError;
  String get address => throw _privateConstructorUsedError;
  @JsonKey(name: 'khateeb_name')
  String? get khateebName => throw _privateConstructorUsedError;

  /// Serializes this JummahConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of JummahConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $JummahConfigCopyWith<JummahConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $JummahConfigCopyWith<$Res> {
  factory $JummahConfigCopyWith(
    JummahConfig value,
    $Res Function(JummahConfig) then,
  ) = _$JummahConfigCopyWithImpl<$Res, JummahConfig>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'khutbah_time') String khutbahTime,
    @JsonKey(name: 'jummah_time') String jummahTime,
    String address,
    @JsonKey(name: 'khateeb_name') String? khateebName,
  });
}

/// @nodoc
class _$JummahConfigCopyWithImpl<$Res, $Val extends JummahConfig>
    implements $JummahConfigCopyWith<$Res> {
  _$JummahConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of JummahConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? khutbahTime = null,
    Object? jummahTime = null,
    Object? address = null,
    Object? khateebName = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            khutbahTime: null == khutbahTime
                ? _value.khutbahTime
                : khutbahTime // ignore: cast_nullable_to_non_nullable
                      as String,
            jummahTime: null == jummahTime
                ? _value.jummahTime
                : jummahTime // ignore: cast_nullable_to_non_nullable
                      as String,
            address: null == address
                ? _value.address
                : address // ignore: cast_nullable_to_non_nullable
                      as String,
            khateebName: freezed == khateebName
                ? _value.khateebName
                : khateebName // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$JummahConfigImplCopyWith<$Res>
    implements $JummahConfigCopyWith<$Res> {
  factory _$$JummahConfigImplCopyWith(
    _$JummahConfigImpl value,
    $Res Function(_$JummahConfigImpl) then,
  ) = __$$JummahConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'khutbah_time') String khutbahTime,
    @JsonKey(name: 'jummah_time') String jummahTime,
    String address,
    @JsonKey(name: 'khateeb_name') String? khateebName,
  });
}

/// @nodoc
class __$$JummahConfigImplCopyWithImpl<$Res>
    extends _$JummahConfigCopyWithImpl<$Res, _$JummahConfigImpl>
    implements _$$JummahConfigImplCopyWith<$Res> {
  __$$JummahConfigImplCopyWithImpl(
    _$JummahConfigImpl _value,
    $Res Function(_$JummahConfigImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of JummahConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? khutbahTime = null,
    Object? jummahTime = null,
    Object? address = null,
    Object? khateebName = freezed,
  }) {
    return _then(
      _$JummahConfigImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        khutbahTime: null == khutbahTime
            ? _value.khutbahTime
            : khutbahTime // ignore: cast_nullable_to_non_nullable
                  as String,
        jummahTime: null == jummahTime
            ? _value.jummahTime
            : jummahTime // ignore: cast_nullable_to_non_nullable
                  as String,
        address: null == address
            ? _value.address
            : address // ignore: cast_nullable_to_non_nullable
                  as String,
        khateebName: freezed == khateebName
            ? _value.khateebName
            : khateebName // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$JummahConfigImpl implements _JummahConfig {
  const _$JummahConfigImpl({
    required this.id,
    @JsonKey(name: 'khutbah_time') required this.khutbahTime,
    @JsonKey(name: 'jummah_time') required this.jummahTime,
    required this.address,
    @JsonKey(name: 'khateeb_name') this.khateebName,
  });

  factory _$JummahConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$JummahConfigImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'khutbah_time')
  final String khutbahTime;
  @override
  @JsonKey(name: 'jummah_time')
  final String jummahTime;
  @override
  final String address;
  @override
  @JsonKey(name: 'khateeb_name')
  final String? khateebName;

  @override
  String toString() {
    return 'JummahConfig(id: $id, khutbahTime: $khutbahTime, jummahTime: $jummahTime, address: $address, khateebName: $khateebName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$JummahConfigImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.khutbahTime, khutbahTime) ||
                other.khutbahTime == khutbahTime) &&
            (identical(other.jummahTime, jummahTime) ||
                other.jummahTime == jummahTime) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.khateebName, khateebName) ||
                other.khateebName == khateebName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    khutbahTime,
    jummahTime,
    address,
    khateebName,
  );

  /// Create a copy of JummahConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$JummahConfigImplCopyWith<_$JummahConfigImpl> get copyWith =>
      __$$JummahConfigImplCopyWithImpl<_$JummahConfigImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$JummahConfigImplToJson(this);
  }
}

abstract class _JummahConfig implements JummahConfig {
  const factory _JummahConfig({
    required final String id,
    @JsonKey(name: 'khutbah_time') required final String khutbahTime,
    @JsonKey(name: 'jummah_time') required final String jummahTime,
    required final String address,
    @JsonKey(name: 'khateeb_name') final String? khateebName,
  }) = _$JummahConfigImpl;

  factory _JummahConfig.fromJson(Map<String, dynamic> json) =
      _$JummahConfigImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'khutbah_time')
  String get khutbahTime;
  @override
  @JsonKey(name: 'jummah_time')
  String get jummahTime;
  @override
  String get address;
  @override
  @JsonKey(name: 'khateeb_name')
  String? get khateebName;

  /// Create a copy of JummahConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$JummahConfigImplCopyWith<_$JummahConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
