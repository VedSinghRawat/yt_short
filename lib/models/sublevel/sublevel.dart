// ignore_for_file: public_member_api_docs, sort_constructors_first
import '../models.dart';

class SubLevel {
  final Video? video;
  final SpeechExerciseDTO? speechExercise;

  SubLevel({
    this.video,
    this.speechExercise,
  });

  String get levelId => speechExercise?.levelId ?? video?.levelId ?? '';
  int get subLevel => speechExercise?.subLevel ?? video?.subLevel ?? 0;
  String get id => speechExercise?.id ?? video?.id ?? '';
  DateTime get createdAt => speechExercise?.createdAt ?? video?.createdAt ?? DateTime.now();
  DateTime get modifiedAt => speechExercise?.updatedAt ?? video?.updatedAt ?? DateTime.now();
  bool get isSpeechExercise => speechExercise != null;
  bool get isVideo => video != null;

  SubLevel copyWith({
    Video? video,
    SpeechExerciseDTO? speechExercise,
  }) {
    return SubLevel(
      video: video ?? this.video,
      speechExercise: speechExercise ?? this.speechExercise,
    );
  }

  factory SubLevel.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('text')) {
      return SubLevel(speechExercise: SpeechExerciseDTO.fromJson(json));
    } else if (json.containsKey('ytId')) {
      return SubLevel(video: Video.fromJson(json));
    }
    throw Exception("Invalid sublevel type");
  }

  Map<String, dynamic> toJson() {
    if (speechExercise != null) {
      return speechExercise!.toJson();
    } else if (video != null) {
      return video!.toJson();
    }
    throw Exception("Invalid sublevel type");
  }
}
