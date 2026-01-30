import 'package:freezed_annotation/freezed_annotation.dart';

part 'teacher_model.freezed.dart';
part 'teacher_model.g.dart';

@freezed
class TeacherModel with _$TeacherModel {
  const factory TeacherModel({
    required int id,
    required String name,
    String? bio,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _TeacherModel;

  factory TeacherModel.fromJson(Map<String, dynamic> json) =>
      _$TeacherModelFromJson(json);
}
