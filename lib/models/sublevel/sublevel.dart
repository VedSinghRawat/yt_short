import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:myapp/models/speech_exercise/speech_exercise.dart';
import 'package:myapp/models/video/video.dart';

part 'sublevel.freezed.dart';
part 'sublevel.g.dart';

@freezed
class Dialogue with _$Dialogue {
  const factory Dialogue({
    required String text,
    required double time,
    required String audioFilename,
    required int zipNum,
    required String hindiText,
    required String hinglishText,
  }) = _Dialogue;

  factory Dialogue.fromJson(Map<String, dynamic> json) => _$DialogueFromJson(json);
}

@freezed
class SubLevel with _$SubLevel {
  const factory SubLevel.speechExercise(SpeechExercise speechExercise) = _SpeechExercise;
  const factory SubLevel.video(Video video) = _Video;

  const SubLevel._();

  factory SubLevel.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {"text": _} => SubLevel.speechExercise(SpeechExercise.fromJson(json)),
      _ => SubLevel.video(Video.fromJson(json)),
    };
  }

  factory SubLevel.fromSubLevelDTO(SubLevelDTO subLevelDTO, int level, int index, String levelId) {
    return subLevelDTO.when(
      speechExercise:
          (dto) => SubLevel.speechExercise(
            SpeechExercise(
              level: level,
              index: index,
              levelId: levelId,
              text: dto.text,
              pauseAt: dto.pauseAt,
              videoFilename: dto.videoFilename,
              dialogues: dto.dialogues,
              audioFilename: dto.audioFilename,
            ),
          ),
      video:
          (dto) => SubLevel.video(
            Video(
              level: level,
              index: index,
              levelId: levelId,
              videoFilename: dto.videoFilename,
              dialogues: dto.dialogues,
            ),
          ),
    );
  }

  String get levelId => when(
    speechExercise: (speechExercise) => speechExercise.levelId,
    video: (video) => video.levelId,
  );

  int get level =>
      when(speechExercise: (speechExercise) => speechExercise.level, video: (video) => video.level);

  int get index =>
      when(speechExercise: (speechExercise) => speechExercise.index, video: (video) => video.index);

  String get videoFilename => when(
    speechExercise: (speechExercise) => speechExercise.videoFilename,
    video: (video) => video.videoFilename,
  );

  List<Dialogue> get dialogues => when(
    speechExercise: (speechExercise) => speechExercise.dialogues,
    video: (video) => video.dialogues,
  );

  bool get isVideo => this is _Video;

  bool get isSpeechExercise => this is _SpeechExercise;
}

@freezed
class SubLevelDTO with _$SubLevelDTO {
  const factory SubLevelDTO.speechExercise(SpeechExerciseDTO speechExercise) = _SpeechExerciseDTO;
  const factory SubLevelDTO.video(VideoDTO video) = _VideoDTO;

  const SubLevelDTO._();

  factory SubLevelDTO.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {"text": _} => SubLevelDTO.speechExercise(SpeechExerciseDTO.fromJson(json)),
      _ => SubLevelDTO.video(VideoDTO.fromJson(json)),
    };
  }

  bool get isSpeechExercise => this is _SpeechExerciseDTO;

  Map<String, dynamic> toJson() {
    return when(
      speechExercise: (speechExercise) => speechExercise.toJson(),
      video: (video) => video.toJson(),
    );
  }

  String get videoFilename => when(
    speechExercise: (speechExercise) => speechExercise.videoFilename,
    video: (video) => video.videoFilename,
  );

  List<Dialogue> get dialogues => when(
    speechExercise: (speechExercise) => speechExercise.dialogues,
    video: (video) => video.dialogues,
  );
}
