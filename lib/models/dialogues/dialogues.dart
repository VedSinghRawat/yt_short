import 'package:freezed_annotation/freezed_annotation.dart';

part 'dialogues.freezed.dart';
part 'dialogues.g.dart';

@freezed
class Dialogue with _$Dialogue {
  const factory Dialogue({
    required String id,
    required int zipNum,
    required String text,
    required String hindiText,
    required String hinglishText,
  }) = _Dialogue;

  factory Dialogue.fromJson(Map<String, dynamic> json) => _$DialogueFromJson(json);

  factory Dialogue.fromDTO(DialogueDTO dto, String id) {
    return Dialogue(
      id: id,
      zipNum: dto.zipNum,
      text: dto.text,
      hindiText: dto.hindiText,
      hinglishText: dto.hinglishText,
    );
  }
}

@freezed
class DialogueDTO with _$DialogueDTO {
  const factory DialogueDTO({
    required int zipNum,
    required String text,
    required String hindiText,
    required String hinglishText,
  }) = _DialogueDTO;

  factory DialogueDTO.fromJson(Map<String, dynamic> json) => _$DialogueDTOFromJson(json);
}
