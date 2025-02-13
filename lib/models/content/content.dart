import '../models.dart';

class Content {
  final Video? _video;
  final SpeechExercise? speechExercise;

  Content(this._video, this.speechExercise);

  int get level => speechExercise?.level ?? _video?.level ?? 0;
  int get subLevel => speechExercise?.subLevel ?? _video?.subLevel ?? 0;
  String get ytId => speechExercise?.ytId ?? _video?.ytId ?? '';
  DateTime get createdAt => speechExercise?.createdAt ?? _video?.createdAt ?? DateTime.now();
  DateTime get modifiedAt => speechExercise?.updatedAt ?? _video?.updatedAt ?? DateTime.now();
  bool get isSpeechExercise => speechExercise != null;
  bool get isVideo => _video != null;
}
