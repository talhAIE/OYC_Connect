import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_model.freezed.dart';
part 'event_model.g.dart';

@freezed
class Event with _$Event {
  const factory Event({
    required int id,
    required String title,
    String? description,
    @JsonKey(name: 'event_date') required DateTime eventDate,
    String? location,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'is_featured') @Default(false) bool isFeatured,
  }) = _Event;

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);
}
