class Media {
  final String audio;
  final String video;

  Media({required this.audio, required this.video});
}

class CachedData extends Media {
  final int timestamp;

  CachedData({required super.audio, required super.video, required this.timestamp});
}
