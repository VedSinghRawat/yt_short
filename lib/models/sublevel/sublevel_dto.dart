import 'package:json_annotation/json_annotation.dart';

part 'sublevel_dto.g.dart';

@JsonSerializable()
class SubLevelDto {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int zipNumber;

  const SubLevelDto({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.zipNumber,
  });

  factory SubLevelDto.fromJson(Map<String, dynamic> json) => _$SubLevelDtoFromJson(json);
  Map<String, dynamic> toJson() => _$SubLevelDtoToJson(this);

  SubLevelDto copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? zipNumber,
  }) {
    return SubLevelDto(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      zipNumber: zipNumber ?? this.zipNumber,
    );
  }
}
