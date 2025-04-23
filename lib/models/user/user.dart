import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:myapp/core/shared_pref.dart';

part 'user.freezed.dart';
part 'user.g.dart';

enum PrefLang { hindi, hinglish }

@freezed
class UserModel with _$UserModel implements SharedPrefClass {
  const UserModel._();

  const factory UserModel({
    required String email,
    required String levelId,
    required int subLevel,
    required String created,
    required String modified,
    required String maxLevelId,
    required int maxSubLevel,
    required int lastSeen,
    required int lastProgress,
    required UserRole role,
    required int doneToday,
    required int level,
    required int maxLevel,
    required PrefLang? prefLang,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

  factory UserModel.fromUserDTO(UserDTO dto, int level, int maxLevel) {
    final jsonDTO = dto.toJson();
    jsonDTO['level'] = level;
    jsonDTO['maxLevel'] = maxLevel;

    return UserModel.fromJson(jsonDTO);
  }

  bool get isAdmin => false;
}

@freezed
class UserDTO with _$UserDTO {
  const UserDTO._();

  const factory UserDTO({
    required String email,
    required String levelId,
    required int subLevel,
    required String created,
    required String modified,
    required String maxLevelId,
    required int maxSubLevel,
    required int lastSeen,
    required int lastProgress,
    required UserRole role,
    required int doneToday,
    required PrefLang? prefLang,
  }) = _UserDTO;

  factory UserDTO.fromJson(Map<String, dynamic> json) => _$UserDTOFromJson(json);
}

enum UserRole { admin, student }
