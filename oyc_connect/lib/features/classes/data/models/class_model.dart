import 'package:freezed_annotation/freezed_annotation.dart';

part 'class_model.freezed.dart';
part 'class_model.g.dart';

@freezed
class ClassModel with _$ClassModel {
  const factory ClassModel({
    required int id,
    required String name,
    String? description,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _ClassModel;

  factory ClassModel.fromJson(Map<String, dynamic> json) =>
      _$ClassModelFromJson(json);
}
