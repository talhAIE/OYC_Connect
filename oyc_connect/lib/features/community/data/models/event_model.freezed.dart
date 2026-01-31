// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'event_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Event _$EventFromJson(Map<String, dynamic> json) {
  return _Event.fromJson(json);
}

/// @nodoc
mixin _$Event {
  int get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'event_date')
  DateTime get eventDate => throw _privateConstructorUsedError;
  String? get location => throw _privateConstructorUsedError;
  @JsonKey(name: 'image_url')
  String? get imageUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_featured')
  bool get isFeatured => throw _privateConstructorUsedError; // New fields for enhanced event details
  @JsonKey(name: 'event_type')
  String? get eventType => throw _privateConstructorUsedError;
  String? get organizer => throw _privateConstructorUsedError;
  @JsonKey(name: 'contact_info')
  String? get contactInfo => throw _privateConstructorUsedError;
  @JsonKey(name: 'registration_link')
  String? get registrationLink => throw _privateConstructorUsedError;
  @JsonKey(name: 'end_time')
  DateTime? get endTime => throw _privateConstructorUsedError;
  int? get capacity => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_registration_required')
  bool get isRegistrationRequired => throw _privateConstructorUsedError;

  /// Serializes this Event to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Event
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EventCopyWith<Event> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EventCopyWith<$Res> {
  factory $EventCopyWith(Event value, $Res Function(Event) then) =
      _$EventCopyWithImpl<$Res, Event>;
  @useResult
  $Res call({
    int id,
    String title,
    String? description,
    @JsonKey(name: 'event_date') DateTime eventDate,
    String? location,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'is_featured') bool isFeatured,
    @JsonKey(name: 'event_type') String? eventType,
    String? organizer,
    @JsonKey(name: 'contact_info') String? contactInfo,
    @JsonKey(name: 'registration_link') String? registrationLink,
    @JsonKey(name: 'end_time') DateTime? endTime,
    int? capacity,
    @JsonKey(name: 'is_registration_required') bool isRegistrationRequired,
  });
}

/// @nodoc
class _$EventCopyWithImpl<$Res, $Val extends Event>
    implements $EventCopyWith<$Res> {
  _$EventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Event
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = freezed,
    Object? eventDate = null,
    Object? location = freezed,
    Object? imageUrl = freezed,
    Object? isFeatured = null,
    Object? eventType = freezed,
    Object? organizer = freezed,
    Object? contactInfo = freezed,
    Object? registrationLink = freezed,
    Object? endTime = freezed,
    Object? capacity = freezed,
    Object? isRegistrationRequired = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            eventDate: null == eventDate
                ? _value.eventDate
                : eventDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            location: freezed == location
                ? _value.location
                : location // ignore: cast_nullable_to_non_nullable
                      as String?,
            imageUrl: freezed == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            isFeatured: null == isFeatured
                ? _value.isFeatured
                : isFeatured // ignore: cast_nullable_to_non_nullable
                      as bool,
            eventType: freezed == eventType
                ? _value.eventType
                : eventType // ignore: cast_nullable_to_non_nullable
                      as String?,
            organizer: freezed == organizer
                ? _value.organizer
                : organizer // ignore: cast_nullable_to_non_nullable
                      as String?,
            contactInfo: freezed == contactInfo
                ? _value.contactInfo
                : contactInfo // ignore: cast_nullable_to_non_nullable
                      as String?,
            registrationLink: freezed == registrationLink
                ? _value.registrationLink
                : registrationLink // ignore: cast_nullable_to_non_nullable
                      as String?,
            endTime: freezed == endTime
                ? _value.endTime
                : endTime // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            capacity: freezed == capacity
                ? _value.capacity
                : capacity // ignore: cast_nullable_to_non_nullable
                      as int?,
            isRegistrationRequired: null == isRegistrationRequired
                ? _value.isRegistrationRequired
                : isRegistrationRequired // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$EventImplCopyWith<$Res> implements $EventCopyWith<$Res> {
  factory _$$EventImplCopyWith(
    _$EventImpl value,
    $Res Function(_$EventImpl) then,
  ) = __$$EventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String title,
    String? description,
    @JsonKey(name: 'event_date') DateTime eventDate,
    String? location,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'is_featured') bool isFeatured,
    @JsonKey(name: 'event_type') String? eventType,
    String? organizer,
    @JsonKey(name: 'contact_info') String? contactInfo,
    @JsonKey(name: 'registration_link') String? registrationLink,
    @JsonKey(name: 'end_time') DateTime? endTime,
    int? capacity,
    @JsonKey(name: 'is_registration_required') bool isRegistrationRequired,
  });
}

/// @nodoc
class __$$EventImplCopyWithImpl<$Res>
    extends _$EventCopyWithImpl<$Res, _$EventImpl>
    implements _$$EventImplCopyWith<$Res> {
  __$$EventImplCopyWithImpl(
    _$EventImpl _value,
    $Res Function(_$EventImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Event
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = freezed,
    Object? eventDate = null,
    Object? location = freezed,
    Object? imageUrl = freezed,
    Object? isFeatured = null,
    Object? eventType = freezed,
    Object? organizer = freezed,
    Object? contactInfo = freezed,
    Object? registrationLink = freezed,
    Object? endTime = freezed,
    Object? capacity = freezed,
    Object? isRegistrationRequired = null,
  }) {
    return _then(
      _$EventImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        eventDate: null == eventDate
            ? _value.eventDate
            : eventDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        location: freezed == location
            ? _value.location
            : location // ignore: cast_nullable_to_non_nullable
                  as String?,
        imageUrl: freezed == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        isFeatured: null == isFeatured
            ? _value.isFeatured
            : isFeatured // ignore: cast_nullable_to_non_nullable
                  as bool,
        eventType: freezed == eventType
            ? _value.eventType
            : eventType // ignore: cast_nullable_to_non_nullable
                  as String?,
        organizer: freezed == organizer
            ? _value.organizer
            : organizer // ignore: cast_nullable_to_non_nullable
                  as String?,
        contactInfo: freezed == contactInfo
            ? _value.contactInfo
            : contactInfo // ignore: cast_nullable_to_non_nullable
                  as String?,
        registrationLink: freezed == registrationLink
            ? _value.registrationLink
            : registrationLink // ignore: cast_nullable_to_non_nullable
                  as String?,
        endTime: freezed == endTime
            ? _value.endTime
            : endTime // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        capacity: freezed == capacity
            ? _value.capacity
            : capacity // ignore: cast_nullable_to_non_nullable
                  as int?,
        isRegistrationRequired: null == isRegistrationRequired
            ? _value.isRegistrationRequired
            : isRegistrationRequired // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$EventImpl implements _Event {
  const _$EventImpl({
    required this.id,
    required this.title,
    this.description,
    @JsonKey(name: 'event_date') required this.eventDate,
    this.location,
    @JsonKey(name: 'image_url') this.imageUrl,
    @JsonKey(name: 'is_featured') this.isFeatured = false,
    @JsonKey(name: 'event_type') this.eventType,
    this.organizer,
    @JsonKey(name: 'contact_info') this.contactInfo,
    @JsonKey(name: 'registration_link') this.registrationLink,
    @JsonKey(name: 'end_time') this.endTime,
    this.capacity,
    @JsonKey(name: 'is_registration_required')
    this.isRegistrationRequired = false,
  });

  factory _$EventImpl.fromJson(Map<String, dynamic> json) =>
      _$$EventImplFromJson(json);

  @override
  final int id;
  @override
  final String title;
  @override
  final String? description;
  @override
  @JsonKey(name: 'event_date')
  final DateTime eventDate;
  @override
  final String? location;
  @override
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @override
  @JsonKey(name: 'is_featured')
  final bool isFeatured;
  // New fields for enhanced event details
  @override
  @JsonKey(name: 'event_type')
  final String? eventType;
  @override
  final String? organizer;
  @override
  @JsonKey(name: 'contact_info')
  final String? contactInfo;
  @override
  @JsonKey(name: 'registration_link')
  final String? registrationLink;
  @override
  @JsonKey(name: 'end_time')
  final DateTime? endTime;
  @override
  final int? capacity;
  @override
  @JsonKey(name: 'is_registration_required')
  final bool isRegistrationRequired;

  @override
  String toString() {
    return 'Event(id: $id, title: $title, description: $description, eventDate: $eventDate, location: $location, imageUrl: $imageUrl, isFeatured: $isFeatured, eventType: $eventType, organizer: $organizer, contactInfo: $contactInfo, registrationLink: $registrationLink, endTime: $endTime, capacity: $capacity, isRegistrationRequired: $isRegistrationRequired)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EventImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.eventDate, eventDate) ||
                other.eventDate == eventDate) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.isFeatured, isFeatured) ||
                other.isFeatured == isFeatured) &&
            (identical(other.eventType, eventType) ||
                other.eventType == eventType) &&
            (identical(other.organizer, organizer) ||
                other.organizer == organizer) &&
            (identical(other.contactInfo, contactInfo) ||
                other.contactInfo == contactInfo) &&
            (identical(other.registrationLink, registrationLink) ||
                other.registrationLink == registrationLink) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.capacity, capacity) ||
                other.capacity == capacity) &&
            (identical(other.isRegistrationRequired, isRegistrationRequired) ||
                other.isRegistrationRequired == isRegistrationRequired));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    description,
    eventDate,
    location,
    imageUrl,
    isFeatured,
    eventType,
    organizer,
    contactInfo,
    registrationLink,
    endTime,
    capacity,
    isRegistrationRequired,
  );

  /// Create a copy of Event
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EventImplCopyWith<_$EventImpl> get copyWith =>
      __$$EventImplCopyWithImpl<_$EventImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EventImplToJson(this);
  }
}

abstract class _Event implements Event {
  const factory _Event({
    required final int id,
    required final String title,
    final String? description,
    @JsonKey(name: 'event_date') required final DateTime eventDate,
    final String? location,
    @JsonKey(name: 'image_url') final String? imageUrl,
    @JsonKey(name: 'is_featured') final bool isFeatured,
    @JsonKey(name: 'event_type') final String? eventType,
    final String? organizer,
    @JsonKey(name: 'contact_info') final String? contactInfo,
    @JsonKey(name: 'registration_link') final String? registrationLink,
    @JsonKey(name: 'end_time') final DateTime? endTime,
    final int? capacity,
    @JsonKey(name: 'is_registration_required')
    final bool isRegistrationRequired,
  }) = _$EventImpl;

  factory _Event.fromJson(Map<String, dynamic> json) = _$EventImpl.fromJson;

  @override
  int get id;
  @override
  String get title;
  @override
  String? get description;
  @override
  @JsonKey(name: 'event_date')
  DateTime get eventDate;
  @override
  String? get location;
  @override
  @JsonKey(name: 'image_url')
  String? get imageUrl;
  @override
  @JsonKey(name: 'is_featured')
  bool get isFeatured; // New fields for enhanced event details
  @override
  @JsonKey(name: 'event_type')
  String? get eventType;
  @override
  String? get organizer;
  @override
  @JsonKey(name: 'contact_info')
  String? get contactInfo;
  @override
  @JsonKey(name: 'registration_link')
  String? get registrationLink;
  @override
  @JsonKey(name: 'end_time')
  DateTime? get endTime;
  @override
  int? get capacity;
  @override
  @JsonKey(name: 'is_registration_required')
  bool get isRegistrationRequired;

  /// Create a copy of Event
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EventImplCopyWith<_$EventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
