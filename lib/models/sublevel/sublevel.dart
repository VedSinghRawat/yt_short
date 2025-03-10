// ignore_for_file: public_member_api_docs, sort_constructors_first
import '../models.dart';

class Sublevel {
  final Video? video;
  final SpeechExercise? speechExercise;

  Sublevel(
    this.video,
    this.speechExercise,
  );

  int get level => speechExercise?.level ?? video?.level ?? 0;
  int get subLevel => speechExercise?.subLevel ?? video?.subLevel ?? 0;
  String get ytId => speechExercise?.ytId ?? video?.ytId ?? '';
  DateTime get createdAt => speechExercise?.createdAt ?? video?.createdAt ?? DateTime.now();
  DateTime get modifiedAt => speechExercise?.updatedAt ?? video?.updatedAt ?? DateTime.now();
  bool get isSpeechExercise => speechExercise != null;
  bool get isVideo => video != null;

  Sublevel copyWith({
    Video? video,
    SpeechExercise? speechExercise,
  }) {
    return Sublevel(
      video ?? this.video,
      speechExercise ?? this.speechExercise,
    );
  }
}
