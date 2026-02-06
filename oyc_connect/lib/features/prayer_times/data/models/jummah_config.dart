import 'package:freezed_annotation/freezed_annotation.dart';

part 'jummah_config.freezed.dart';
part 'jummah_config.g.dart';

@freezed
class JummahConfig with _$JummahConfig {
  const factory JummahConfig({
    required String id,
    @JsonKey(name: 'khutbah_time') required String khutbahTime,
    @JsonKey(name: 'jummah_time') required String jummahTime,
    required String address,
    @JsonKey(name: 'khateeb_name') String? khateebName,
  }) = _JummahConfig;

  factory JummahConfig.fromJson(Map<String, dynamic> json) =>
      _$JummahConfigFromJson(json);
}
