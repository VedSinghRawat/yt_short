import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:myapp/models/speech_exercise/speech_exercise.dart';
import 'package:myapp/models/video/video.dart';
import 'package:myapp/models/arrange_exercise/arrange_exercise.dart';
import 'package:myapp/models/fill_exercise/fill_exercise.dart';

part 'sublevel.freezed.dart';

enum SubLevelType { speech, video, fill, arrange }

@freezed
class SubLevel with _$SubLevel {
  const factory SubLevel.speechExercise(SpeechExercise speechExercise) = _SpeechExercise;
  const factory SubLevel.video(Video video) = _Video;
  const factory SubLevel.arrangeExercise(ArrangeExercise arrangeExercise) = _ArrangeExercise;
  const factory SubLevel.fillExercise(FillExercise fillExercise) = _FillExercise;

  const SubLevel._();

  factory SubLevel.fromDTO(SubLevelDTO subLevelDTO, int level, int index, String levelId) {
    return subLevelDTO.when(
      speechExercise:
          (dto) => SubLevel.speechExercise(
            SpeechExercise(level: level, index: index, levelId: levelId, text: dto.text, id: dto.id),
          ),
      video:
          (dto) =>
              SubLevel.video(Video(level: level, index: index, levelId: levelId, id: dto.id, dialogues: dto.dialogues)),
      arrangeExercise:
          (dto) => SubLevel.arrangeExercise(
            ArrangeExercise(level: level, index: index, levelId: levelId, text: dto.text, id: dto.id),
          ),
      fillExercise:
          (dto) => SubLevel.fillExercise(
            FillExercise(level: level, index: index, levelId: levelId, text: dto.text, id: dto.id),
          ),
    );
  }

  T _mapSublevel<T>(T Function(dynamic) fn) =>
      when(speechExercise: fn, video: fn, arrangeExercise: fn, fillExercise: fn);

  String get levelId => _mapSublevel((e) => e.levelId);
  int get level => _mapSublevel((e) => e.level);
  int get index => _mapSublevel((e) => e.index);
  String get id => _mapSublevel((e) => e.id);

  bool get isVideo => this is _Video;
  bool get isSpeechExercise => this is _SpeechExercise;
  bool get isArrangeExercise => this is _ArrangeExercise;
  bool get isFillExercise => this is _FillExercise;
}

@freezed
class SubLevelDTO with _$SubLevelDTO {
  const factory SubLevelDTO.speechExercise(SpeechExerciseDTO speechExercise) = _SpeechExerciseDTO;
  const factory SubLevelDTO.video(VideoDTO video) = _VideoDTO;
  const factory SubLevelDTO.arrangeExercise(ArrangeExerciseDTO arrangeExercise) = _ArrangeExerciseDTO;
  const factory SubLevelDTO.fillExercise(FillExerciseDTO fillExercise) = _FillExerciseDTO;

  const SubLevelDTO._();

  factory SubLevelDTO.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    return switch (type) {
      'speech' => SubLevelDTO.speechExercise(SpeechExerciseDTO.fromJson(json)),
      'video' => SubLevelDTO.video(VideoDTO.fromJson(json)),
      'arrange' => SubLevelDTO.arrangeExercise(ArrangeExerciseDTO.fromJson(json)),
      'fill' => SubLevelDTO.fillExercise(FillExerciseDTO.fromJson(json)),
      _ => throw Exception('Unknown sublevel type: $type'),
    };
  }

  T _mapSublevel<T>(T Function(dynamic) fn) =>
      when(speechExercise: fn, video: fn, arrangeExercise: fn, fillExercise: fn);

  Map<String, dynamic> toJson() => _mapSublevel((e) => e.toJson());
  String get id => _mapSublevel((e) => e.id);

  bool get isSpeechExercise => this is _SpeechExerciseDTO;
  bool get isVideo => this is _VideoDTO;
  bool get isArrangeExercise => this is _ArrangeExerciseDTO;
  bool get isFillExercise => this is _FillExerciseDTO;
}
